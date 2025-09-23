import 'package:flutter/material.dart';
import '../../models/donation_model.dart';

class DonationDetailsScreen extends StatelessWidget {
  final DonationModel donation;

  const DonationDetailsScreen({
    super.key,
    required this.donation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (donation.taxReceiptId != null)
            IconButton(
              icon: const Icon(Icons.receipt),
              onPressed: () => _showTaxReceipt(context),
              tooltip: 'Tax Receipt',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Charity Information
            _buildCharityInfo(),
            const SizedBox(height: 16),

            // Donation Items
            _buildItemsSection(),
            const SizedBox(height: 16),

            // Pickup Details
            _buildPickupDetails(),
            const SizedBox(height: 16),

            // Timeline
            _buildTimeline(),
            const SizedBox(height: 16),

            // Notes
            if (donation.notes != null && donation.notes!.isNotEmpty)
              _buildNotesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (donation.status) {
      case 'pending':
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.schedule;
        break;
      case 'confirmed':
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        icon = Icons.check_circle;
        break;
      case 'picked_up':
        backgroundColor = Colors.purple.withOpacity(0.1);
        textColor = Colors.purple;
        icon = Icons.local_shipping;
        break;
      case 'completed':
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.done_all;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        icon = Icons.help;
    }

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(),
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharityInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.charityName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Charity Organization',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Donated Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${donation.totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...donation.items.map((item) => _buildItemCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(DonationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: ${item.quantity.toStringAsFixed(1)} ${item.unit}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Est. Value: \$${item.estimatedValue.toStringAsFixed(2)}/${item.unit}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${item.totalValue.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pickup Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (donation.pickupAddress != null && donation.pickupAddress!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Address',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          donation.pickupAddress!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (donation.contactPhone != null && donation.contactPhone!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.phone, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Phone',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          donation.contactPhone!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Donation Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              icon: Icons.create,
              title: 'Donation Created',
              date: donation.createdAt,
              isCompleted: true,
            ),
            if (donation.confirmedAt != null)
              _buildTimelineItem(
                icon: Icons.check_circle,
                title: 'Confirmed by Charity',
                date: donation.confirmedAt!,
                isCompleted: true,
              ),
            if (donation.pickedUpAt != null)
              _buildTimelineItem(
                icon: Icons.local_shipping,
                title: 'Items Picked Up',
                date: donation.pickedUpAt!,
                isCompleted: true,
              ),
            if (donation.completedAt != null)
              _buildTimelineItem(
                icon: Icons.done_all,
                title: 'Donation Completed',
                date: donation.completedAt!,
                isCompleted: true,
              ),
            if (donation.status == 'pending' || donation.status == 'confirmed')
              _buildTimelineItem(
                icon: donation.status == 'pending' ? Icons.schedule : Icons.local_shipping,
                title: donation.status == 'pending' 
                    ? 'Awaiting Confirmation' 
                    : 'Awaiting Pickup',
                date: null,
                isCompleted: false,
                isPending: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required DateTime? date,
    required bool isCompleted,
    bool isPending = false,
  }) {
    Color iconColor = isCompleted ? Colors.green : (isPending ? Colors.orange : Colors.grey);
    Color textColor = isCompleted ? Colors.black87 : (isPending ? Colors.orange : Colors.grey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: iconColor.withOpacity(0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                if (date != null)
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                donation.notes!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDescription() {
    switch (donation.status) {
      case 'pending':
        return 'Your donation is waiting for charity confirmation';
      case 'confirmed':
        return 'The charity has confirmed your donation and will arrange pickup';
      case 'picked_up':
        return 'Your donation has been picked up by the charity';
      case 'completed':
        return 'Your donation has been successfully completed';
      case 'cancelled':
        return 'This donation has been cancelled';
      default:
        return 'Unknown status';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showTaxReceipt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt, color: Colors.green),
            SizedBox(width: 8),
            Text('Tax Receipt'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt ID: ${donation.taxReceiptId}'),
            const SizedBox(height: 8),
            Text('Donation Date: ${_formatDate(donation.completedAt!)}'),
            const SizedBox(height: 8),
            Text('Charity: ${donation.charityName}'),
            const SizedBox(height: 8),
            Text('Total Value: \$${donation.totalValue.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text(
              'This receipt can be used for tax deduction purposes. Please consult with your tax advisor.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
