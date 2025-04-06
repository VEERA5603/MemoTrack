import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MemoDialog extends StatefulWidget {
  final DocumentSnapshot memo;
  final Map<String, dynamic>? lastStatus;
  final String userType;
  final String institutionalId;
  final FirebaseFirestore firestore;
  final List<String> responderTypes;

  const MemoDialog({
    Key? key,
    required this.memo,
    required this.lastStatus,
    required this.userType,
    required this.institutionalId,
    required this.firestore,
    required this.responderTypes,
  }) : super(key: key);

  @override
  _MemoDialogState createState() => _MemoDialogState();
}

class _MemoDialogState extends State<MemoDialog> {
  late TextEditingController _remarksController;
  late String _status;
  late String _workStatus;
  late String _tagUser;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final Color primaryColor = Color(0xFF4285F4); // Google Blue
  final Color secondaryColor = Color(0xFF34A853); // Google Green
  final Color backgroundColor = Color(0xFFF1F3F4); // Light grey background
  @override
  void initState() {
    super.initState();
    _status = widget.lastStatus?['status'] ?? 'not attended';
    _workStatus = widget.lastStatus?['workStatus'] ?? 'incomplete';
    _tagUser = widget.lastStatus?['tagUser'] ?? 'no need';
    _remarksController =
        TextEditingController(text: widget.lastStatus?['remarks'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        return Theme(
            data: ThemeData(
              canvasColor: Colors
                  .white, // Forces the dropdown menu background color to white
            ),
            child: AlertDialog(
              title: Text('Memo Details: ${widget.memo['memoId']}'),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    minWidth: 300,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Memo Details with Responsive Layout
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildDetailChip(
                              'Complaint', widget.memo['complaints']),
                          _buildDetailChip(
                              'Department', widget.memo['department']),
                          _buildDetailChip('Block', widget.memo['blockName']),
                          _buildDetailChip('Floor No', widget.memo['floorNo']),
                          _buildDetailChip('Ward No', widget.memo['wardNo']),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Status Dropdowns with Responsive Layout
                      if (isNarrow)
                        Column(
                          children: [
                            _buildStatusDropdown(),
                            SizedBox(height: 10),
                            _buildWorkStatusDropdown(),
                            SizedBox(height: 10),
                            _buildTagUserDropdown(),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(child: _buildStatusDropdown()),
                            SizedBox(width: 10),
                            Expanded(child: _buildWorkStatusDropdown()),
                            SizedBox(width: 10),
                            Expanded(child: _buildTagUserDropdown()),
                          ],
                        ),

                      SizedBox(height: 20),

                      // Remarks TextField
                      _buildRemarksField(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _submitMemoUpdate();
                    Navigator.of(context).pop();
                  },
                  child: Text('Submit'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
              ],
            ));
      },
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Chip(
      label: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
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
          // Reset work status and tag user if status changes to 'not attended'
          if (_status == 'not attended') {
            _workStatus = 'incomplete';
            _tagUser = 'no need';
          }
        });
      },
    );
  }

  Widget _buildWorkStatusDropdown() {
    return DropdownButtonFormField<String>(
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
      onChanged: _status == 'attended'
          ? (value) {
              setState(() {
                _workStatus = value!;
              });
            }
          : null,
    );
  }

  Widget _buildTagUserDropdown() {
    return DropdownButtonFormField<String>(
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
      onChanged: _status == 'attended'
          ? (value) {
              setState(() {
                _tagUser = value!;
              });
            }
          : null,
    );
  }

  Widget _buildRemarksField() {
    return TextField(
      controller: _remarksController,
      decoration: InputDecoration(
        labelText: 'Remarks',
        border: OutlineInputBorder(),
      ),
      enabled: _status == 'attended',
      maxLines: 3,
    );
  }

  void _submitMemoUpdate() {
    try {
      widget.firestore.collection('memo').doc(widget.memo.id).update({
        'tagUser': _tagUser,
        'workerStatuses': FieldValue.arrayUnion([
          {
            'status': _status,
            'workStatus': _workStatus,
            'tagUser': _tagUser,
            'remarks': _remarksController.text,
            'timestamp': DateTime.now().toIso8601String(),
            'institutionalId': widget.institutionalId,
            'userType': widget.userType,
          }
        ]),
      });
      _showToast('Memo updated successfully');
    } catch (e) {
      _showToast('Error updating memo', isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? Colors.red : secondaryColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }
}
