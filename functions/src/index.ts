import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Send push notification when notification document is created
 * Triggers when a document is added to 'notifications' collection
 */
export const sendPushNotification = functions
  .firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const notificationData = snapshot.data();
    const notificationId = context.params.notificationId as string;

    console.log(`📬 New notification created: ${notificationId}`);

    try {
      // Get the user ID from the notification
      const userId = notificationData.userId;

      if (!userId) {
        console.log("❌ No userId in notification document");
        return null;
      }

      // Get user's FCM tokens from Firestore
      const userRef = admin.firestore().collection("users").doc(userId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        console.log(`❌ User ${userId} not found`);
        return null;
      }

      const userData = userDoc.data() || {};

      // Collect tokens: primary field + tokens subcollection (fallback)
      const tokensSet = new Set<string>();

      const primaryToken = (userData as {fcmToken?: string}).fcmToken;
      if (
        primaryToken &&
        typeof primaryToken === "string" &&
        primaryToken.trim().length > 0
      ) {
        tokensSet.add(primaryToken.trim());
      }

      // Fallback to tokens subcollection (grab a few most recent tokens)
      if (tokensSet.size === 0) {
        const tokensSnap = await userRef
          .collection("tokens")
          .orderBy("refreshedAt", "desc")
          .orderBy("createdAt", "desc")
          .limit(5)
          .get();

        tokensSnap.forEach((doc) => {
          const data = doc.data() as {token?: string};
          const t = data.token;
          if (t && typeof t === "string" && t.trim().length > 0) {
            tokensSet.add(t.trim());
          }
        });
      }

      const tokens = Array.from(tokensSet);
      if (tokens.length === 0) {
        console.log(`⚠️ No FCM token(s) for user ${userId}`);
        try {
          await snapshot.ref.update({
            sent: false,
            tokenMissing: true,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } catch (uErr) {
          console.error("⚠️ Failed to mark notification as tokenMissing", uErr);
        }
        return null;
      }

      // Prepare data payload (all values must be strings)
      const dataPayload: {[key: string]: string} = {
        notificationId: notificationId,
        type: notificationData.type || "general",
      };

      // Add custom data from notification
      if (notificationData.data) {
        for (const key in notificationData.data) {
          if (
            Object.prototype.hasOwnProperty.call(notificationData.data, key)
          ) {
            dataPayload[key] = String(notificationData.data[key]);
          }
        }
      }

      // Build a base message (we'll set token per send)
      const baseMessage = {
        notification: {
          title: notificationData.title as string,
          body: notificationData.message as string,
        },
        data: dataPayload,
        android: {
          notification: {
            channelId: "farmlink_notifications",
            sound: "default",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      } as Omit<admin.messaging.Message, "token">;

      let successCount = 0;
      let failureCount = 0;
      for (const token of tokens) {
        try {
          const message: admin.messaging.Message = {
            ...baseMessage,
            token,
          };
          const response = await admin.messaging().send(message);
          successCount++;
          console.log(
            `✅ Sent to token: ${token.substring(0, 12)}... | id: ${response}`,
          );
        } catch (err: unknown) {
          failureCount++;
          console.error(`❌ Failed token: ${token.substring(0, 12)}...`, err);
          // Clean up invalid tokens
          const message = String(err);
          const notRegistered = message.includes(
            "registration-token-not-registered",
          );
          const invalidToken = message.includes(
            "messaging/invalid-registration-token",
          );
          if (notRegistered || invalidToken) {
            try {
              // Attempt to delete from tokens subcollection if present
              const tokenDoc = await userRef
                .collection("tokens")
                .doc(token)
                .get();
              if (tokenDoc.exists) {
                await tokenDoc.ref.delete();
                console.log(`🧹 Removed invalid token doc for user ${userId}`);
              }
              // Also clear primary if it matches
              if (primaryToken === token) {
                await userRef.update({
                  fcmToken: admin.firestore.FieldValue.delete(),
                });
                console.log(`🧹 Cleared primary fcmToken for user ${userId}`);
              }
            } catch (cleanupErr) {
              console.error(
                `⚠️ Cleanup failed for token of user ${userId}`,
                cleanupErr,
              );
            }
          }
        }
      }

      console.log(
        `📊 Send summary for user ${userId}: ` +
          `success=${successCount}, failed=${failureCount}, ` +
          `total=${tokens.length}`,
      );

      // Mark notification as sent in Firestore
      await snapshot.ref.update({
        sent: successCount > 0,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        sendSummary: {successCount, failureCount, total: tokens.length},
      });

      return {success: true};
    } catch (error) {
      console.error("❌ Error sending push notification:", error);

      // Mark notification as failed
      await snapshot.ref.update({
        sent: false,
        error: String(error),
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {success: false, error: String(error)};
    }
  });
