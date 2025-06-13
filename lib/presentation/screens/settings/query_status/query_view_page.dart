import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../utils/colors.dart';

class QueryViewPage extends StatelessWidget {
  const QueryViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Queries',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: currentUserId == null
          ? const Center(child: Text("Not Authenticated"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user_queries')
                  .where('userId', isEqualTo: currentUserId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No Queries Found"));
                }

                final userQueries = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: userQueries.length,
                  itemBuilder: (context, index) {
                    final data =
                        userQueries[index].data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Top Row: Avatar + User Info + Optional Image
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.secondaryColor,
                                child: Text(
                                  data['userName']
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      '',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['userName'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(data['email'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.grey)),
                                    Text(data['phone'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.grey)),
                                    Text(
                                      'Query ID: ${data['query_id'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              if (data['imageUrl'] != null &&
                                  data['imageUrl'].toString().isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    data['imageUrl'],
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          /// Query Message
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              data['message'] ?? '',
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),

                          const SizedBox(height: 14),

                          /// Status and Timestamp Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Status:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(data['status']),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      data['status']?.toUpperCase() ??
                                          'UNKNOWN',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 16, color: Colors.black),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTimestamp(data['timestamp']),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

/// Status chip color
Color _getStatusColor(String? status) {
  switch (status?.toLowerCase()) {
    case 'active':
      return AppColors.primaryColor;
    case 'review':
      return Colors.orange;
    case 'processing':
      return Colors.amber.shade700;
    case 'closed':
      return Colors.redAccent;
    default:
      return Colors.grey;
  }
}

/// Format Firestore Timestamp
String _formatTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  return 'Unknown Time';
}
