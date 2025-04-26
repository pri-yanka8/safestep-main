import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, String>> reports = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      // Fetch reports from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .orderBy('timestamp',
              descending: true) // You can order by timestamp or any other field
          .get();

      final fetchedReports = snapshot.docs.map((doc) {
        final data = doc.data();
        final category =
            data['category'] as String? ?? 'Unknown'; 
        final location =
            data['location'] as String? ?? 'Unknown'; 
        final timestamp = data['timestamp']; 

        final time =
            timestamp != null ? timestamp.toDate().toString() : 'Unknown';
        final date = timestamp != null
            ? timestamp.toDate().toString().split(" ")[0]
            : 'Unknown';

        return {
          'category': category,
          'location': location,
          'time': time,
          'date': date,
        };
      }).toList();

      setState(() {
        reports = fetchedReports;
      });
    } catch (e) {
      print("Error fetching reports: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
      ),
      body: reports.isEmpty
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading spinner if no reports yet
          : ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      report["category"] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report["location"] ?? 'Unknown'),
                        const SizedBox(height: 4),
                        Text(
                          report["time"] ?? 'Unknown',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      report["date"] ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
