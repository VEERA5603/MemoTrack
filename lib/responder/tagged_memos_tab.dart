import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaggedMemoTab extends StatefulWidget {
  final String userType;
  final String institutionalId;
  final FirebaseFirestore firestore;
  final List<String> responderTypes;

  const TaggedMemoTab({
    Key? key,
    required this.userType,
    required this.institutionalId,
    required this.firestore,
    required this.responderTypes,
  }) : super(key: key);

  @override
  State<TaggedMemoTab> createState() => _TaggedMemoTabState();
}

class _TaggedMemoTabState extends State<TaggedMemoTab> {
  Stream<QuerySnapshot> _getTaggedMemoStream() {
    return widget.firestore
        .collection('memo')
        .where('status', whereIn: ['approved', 'completed'])
        .where('tagUser', isEqualTo: widget.userType)
        .snapshots();
  }

  Color _getMemoColor(Map<String, dynamic> memoData) {
    List<dynamic> workStatuses = memoData['workerStatuses'] ?? [];
    if (workStatuses.isEmpty) {
      return Colors.white; // Not attended, incomplete
    }

    var lastStatus = workStatuses.last;
    bool isAttended = lastStatus['status'] == 'attended';
    bool isComplete = lastStatus['workStatus'] == 'complete';

    if (!isAttended && !isComplete) {
      return Colors.red[100]!; // Not attended, incomplete
    } else if (isAttended && !isComplete) {
      return Colors.white; // Attended, incomplete
    }
    return Colors.white; // Attended, complete
  }

  bool _shouldShowMemo(Map<String, dynamic> memoData) {
    List<dynamic> workStatuses = memoData['workerStatuses'] ?? [];
    if (workStatuses.isEmpty) return true;

    var lastStatus = workStatuses.last;
    String status = lastStatus['status'] ?? 'not attended';
    String workStatus = lastStatus['workStatus'] ?? 'incomplete';
    String tagUser = lastStatus['tagUser'] ?? 'no need';

    bool isAttended = status == 'attended';
    bool isComplete = workStatus == 'complete';
    bool isTaggedToOther = tagUser != 'no need' && tagUser != widget.userType;

    return !((isComplete && isTaggedToOther) ||
        (isComplete && tagUser == 'no need'));
  }

  void _showStatusDialog(BuildContext context, DocumentSnapshot memo) {
    List<dynamic> workStatuses = memo['workerStatuses'] ?? [];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
            data: ThemeData(
              canvasColor: Colors
                  .white, // Forces the dropdown menu background color to white
            ),
            child: AlertDialog(
              title: Text('Status History'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: workStatuses.map<Widget>((status) {
                    return Card(
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${status['status']}'),
                            Text('Work Status: ${status['workStatus']}'),
                            Text('Tag User: ${status['tagUser']}'),
                            Text('Remarks: ${status['remarks']}'),
                            Text(
                                'Time: ${DateTime.parse(status['timestamp']).toString()}'),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
              ],
            ));
      },
    );
  }

  void _showUpdateDialog(BuildContext context, DocumentSnapshot memo) {
    Map<String, dynamic> memoData = memo.data() as Map<String, dynamic>;
    final _formKey = GlobalKey<FormState>();
    final _remarksController = TextEditingController();

    // Initialize with default values
    String _status = 'not attended';
    String _workStatus = 'incomplete';
    String _tagUser = 'no need';
    bool _isAttended = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Memo: ${memoData['memoId']}'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Complaint: ${memoData['complaints']}'),
                      Text('Department: ${memoData['department']}'),
                      Text('Block: ${memoData['blockName']}'),
                      Text('Ward No: ${memoData['wardNo']}'),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: ['not attended', 'attended']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _status = value!;
                            _isAttended = value == 'attended';
                            if (!_isAttended) {
                              _workStatus = 'incomplete';
                              _tagUser = 'no need';
                            }
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      if (_isAttended) ...[
                        DropdownButtonFormField<String>(
                          value: _workStatus,
                          decoration: InputDecoration(
                            labelText: 'Work Status',
                            border: OutlineInputBorder(),
                          ),
                          items: ['incomplete', 'complete']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _workStatus = value!;
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _tagUser,
                          decoration: InputDecoration(
                            labelText: 'Tag User',
                            border: OutlineInputBorder(),
                          ),
                          items: ['no need', ...widget.responderTypes]
                              .map((user) => DropdownMenuItem(
                                    value: user,
                                    child: Text(user),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _tagUser = value!;
                            });
                          },
                        ),
                      ],
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _remarksController,
                        decoration: InputDecoration(
                          labelText: 'Remarks',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Map<String, dynamic> newStatus = {
                        'status': _status,
                        'workStatus': _workStatus,
                        'tagUser': _tagUser,
                        'remarks': _remarksController.text,
                        'timestamp': DateTime.now().toIso8601String(),
                        'institutionalId': widget.institutionalId,
                        'userType': widget.userType,
                      };

                      Map<String, dynamic> updateData = {
                        'workerStatuses': FieldValue.arrayUnion([newStatus]),
                      };

                      // Only update tagUser outside the array if it's not "no need" or attended and incomplete
                      if (!(_status == 'attended' &&
                          _workStatus == 'incomplete' &&
                          _tagUser == 'no need')) {
                        updateData['tagUser'] = _tagUser;
                      }

                      // Update status to completed only if all conditions are met
                      if (_status == 'attended' &&
                          _workStatus == 'complete' &&
                          _tagUser == 'no need') {
                        updateData['status'] = 'completed';
                      }

                      try {
                        await widget.firestore
                            .collection('memo')
                            .doc(memo.id)
                            .update(updateData);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Memo updated successfully')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating memo: $e')),
                        );
                      }
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getTaggedMemoStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No memos found'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot memo = snapshot.data!.docs[index];
            Map<String, dynamic> memoData = memo.data() as Map<String, dynamic>;

            if (!_shouldShowMemo(memoData)) {
              return SizedBox.shrink();
            }

            return Card(
              color: _getMemoColor(memoData),
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(
                  'Memo ID: ${memoData['memoId']}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Complaint: ${memoData['complaints']}'),
                    Text('Department: ${memoData['department']}'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _showStatusDialog(context, memo),
                          child: Text('View History'),
                        ),
                        ElevatedButton(
                          onPressed: () => _showUpdateDialog(context, memo),
                          child: Text('Update Status'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
