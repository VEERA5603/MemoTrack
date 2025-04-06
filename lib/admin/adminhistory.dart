import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class History extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('memo')
          .where('status', whereIn: ['completed']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No memos found."));
        }

        final memos = snapshot.data!.docs;

        return ListView.builder(
          itemCount: memos.length,
          itemBuilder: (context, index) {
            final memo = memos[index];
            final memoData = memo.data() as Map<String, dynamic>;
            return Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(
                  "Worker: ${memoData['workerType'] ?? 'N/A'}                                   Status: ${memoData['status']}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Memo ID: ${memoData['memoId'] ?? 'N/A'}"),
                trailing: IconButton(
                  icon: Icon(Icons.download, color: Colors.green),
                  onPressed: () => _showDownloadConfirmation(context, memoData),
                ),
                onTap: () => _showMemoDetails(context, memoData),
              ),
            );
          },
        );
      },
    );
  }

  void _showMemoDetails(BuildContext context, Map<String, dynamic> memoData) {
    showDialog(
      context: context,
      builder: (context) {
        final dialogWidth = MediaQuery.of(context).size.width * 0.9;
        return Theme(
            data: ThemeData(
              canvasColor: Colors
                  .white, // Forces the dropdown menu background color to white
            ),
            child: AlertDialog(
              title: Text("Memo Details"),
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: dialogWidth,
                padding: EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKeyValueRow("Memo ID", memoData['memoId']),
                      _buildKeyValueRow("Worker Type", memoData['workerType']),
                      _buildKeyValueRow("Complaint", memoData['complaints']),
                      _buildKeyValueRow("Department", memoData['department']),
                      _buildKeyValueRow("Block", memoData['blockName']),
                      _buildKeyValueRow("Floor", memoData['floorNo']),
                      _buildKeyValueRow("Ward No", memoData['wardNo']),
                      _buildKeyValueRow("Nurse Name", memoData['nurseName']),
                      _buildKeyValueRow("Shift", memoData['shift']),
                      _buildKeyValueRow("Status", memoData['status']),
                      _buildKeyValueRow(
                          "Timestamp", _formatTimestamp(memoData['timestamp'])),
                      if (memoData['approvedBy'] != null)
                        _buildTable(
                          "Approved By",
                          memoData['approvedBy'],
                          ["institutionalId", "userType", "timestamp"],
                          formatTimestamp: true,
                        ),
                      if (memoData['workerStatuses'] != null)
                        _buildTable(
                          "Worker Statuses",
                          memoData['workerStatuses'],
                          [
                            "institutionalId",
                            "userType",
                            "workStatus",
                            "status",
                            "remarks"
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blue, // Set the text color to blue
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Close"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blue, // Set the text color to blue
                  ),
                  onPressed: () => _downloadAsPDF(context, memoData),
                  child: Text("Download as PDF"),
                ),
              ],
            ));
      },
    );
  }

  void _showDownloadConfirmation(
      BuildContext context, Map<String, dynamic> memoData) {
    showDialog(
        context: context,
        builder: (context) => Theme(
              data: ThemeData(
                canvasColor: Colors
                    .white, // Forces the dropdown menu background color to white
              ),
              child: AlertDialog(
                title: Text("Download Memo"),
                content: Text("Do you want to download this memo as a PDF?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("No"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _downloadAsPDF(context, memoData);
                    },
                    child: Text("Yes"),
                  ),
                ],
              ),
            ));
  }

  Future<void> _downloadAsPDF(
      BuildContext context, Map<String, dynamic> memoData) async {
    final pdf = pw.Document();

    // Generate tables for "Approved By" and "Worker Statuses" if available
    pw.Widget buildTable(
        String title, List<dynamic> data, List<String> columns) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 5),
          pw.Table.fromTextArray(
            headers: columns,
            data: data.map((row) {
              return columns
                  .map((column) => row[column]?.toString() ?? "N/A")
                  .toList();
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
            cellStyle: pw.TextStyle(fontSize: 12),
            border: pw.TableBorder.all(),
          ),
          pw.SizedBox(height: 10),
        ],
      );
    }

    // Main Content
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Memo Details",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                ),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),
                pw.Text("Memo ID: ${memoData['memoId'] ?? 'N/A'}",
                    style: pw.TextStyle(fontSize: 14)),
                pw.Text("Worker Type: ${memoData['workerType'] ?? 'N/A'}",
                    style: pw.TextStyle(fontSize: 14)),
                pw.Text("Complaint: ${memoData['complaints'] ?? 'N/A'}",
                    style: pw.TextStyle(fontSize: 14)),
                pw.Text("Department: ${memoData['department'] ?? 'N/A'}",
                    style: pw.TextStyle(fontSize: 14)),
                pw.Text("Block: ${memoData['blockName'] ?? 'N/A'}",
                    style: pw.TextStyle(fontSize: 14)),
                pw.Text("Floor: ${memoData['floorNo'] ?? 'N/A'}",
                    style: pw.TextStyle(fontSize: 14)),
                pw.Text("Ward No: ${memoData['wardNo'] ?? 'N/A'}",
                    style: pw.TextStyle(fontSize: 14)),
                pw.Text("Nurse Name: ${memoData['nurseName'] ?? 'N/A'}",
                    style: pw.TextStyle(fontSize: 14)),
                pw.Text("Shift: ${memoData['shift'] ?? 'N/A'}",
                    style: pw.TextStyle(fontSize: 14)),
                pw.Text("Status: ${memoData['status'] ?? 'N/A'}",
                    style: pw.TextStyle(fontSize: 14)),
                pw.Text(
                    "Timestamp: ${_formatTimestamp(memoData['timestamp']) ?? 'N/A'}",
                    style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 10),
                if (memoData['approvedBy'] != null)
                  buildTable(
                    "Approved By",
                    List<Map<String, dynamic>>.from(memoData['approvedBy']),
                    ["institutionalId", "userType", "timestamp"],
                  ),
                if (memoData['workerStatuses'] != null)
                  buildTable(
                    "Worker Statuses",
                    List<Map<String, dynamic>>.from(memoData['workerStatuses']),
                    [
                      "institutionalId",
                      "userType",
                      "workStatus",
                      "status",
                      "remarks"
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );

    // Save and Share PDF
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: "Memo_${memoData['memoId']}.pdf");
  }

  Widget _buildKeyValueRow(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$key:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value != null ? value.toString() : "N/A"),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(String title, List<dynamic> items, List<String> columns,
      {bool formatTimestamp = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Table(
          border: TableBorder.all(),
          columnWidths:
              columns.asMap().map((i, _) => MapEntry(i, FlexColumnWidth())),
          children: [
            TableRow(
              children: columns.map((col) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    col,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
            ...items.map((item) {
              final itemData = item as Map<String, dynamic>;
              return TableRow(
                children: columns.map((col) {
                  var value = itemData[col];
                  if (formatTimestamp && col == "timestamp" && value != null) {
                    value = _formatTimestamp(value);
                  }
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(value?.toString() ?? "N/A"),
                  );
                }).toList(),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    } else if (timestamp is String) {
      try {
        final dateTime = DateTime.parse(timestamp);
        return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
      } catch (e) {
        return "Invalid Date";
      }
    }
    return "N/A";
  }
}
