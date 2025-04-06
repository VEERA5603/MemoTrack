import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memo4/user_types.dart';

class ManageUserScreen extends StatefulWidget {
  @override
  _ManageUserScreenState createState() => _ManageUserScreenState();
}

class _ManageUserScreenState extends State<ManageUserScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isExpanded = false;
  String selectedUserId = '';

  // Add user method
  Future<void> _addUser(String institutionalId, String name,
      String mobileNumber, String userType) async {
    try {
      CollectionReference users = _firestore.collection('registerUser');

      // Create a new user
      var newUser = {
        'institutionalId': institutionalId,
        'name': name,
        'mobileNumber': mobileNumber,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await users.add(newUser);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Read user method (for displaying in the list)
  Stream<QuerySnapshot> _getUsers() {
    return _firestore.collection('registerUser').snapshots();
  }

  // Delete user method
  Future<void> _deleteUser(String docId) async {
    try {
      await _firestore.collection('registerUser').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update user method
  Future<void> _updateUser(
      String docId, String name, String mobileNumber, String userType) async {
    try {
      await _firestore.collection('registerUser').doc(docId).update({
        'name': name,
        'mobileNumber': mobileNumber,
        'userType': userType,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show Add User Dialog
  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final _institutionalIdController = TextEditingController();
        final _nameController = TextEditingController();
        final _mobileNumberController = TextEditingController();
        String _selectedUserType = 'Ward Staff Nurse';

        return Theme(
          data: ThemeData(
            canvasColor: Colors
                .white, // Forces the dropdown menu background color to white
          ),
          child: AlertDialog(
            title: Text('Add New User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _institutionalIdController,
                    decoration: InputDecoration(labelText: 'Institutional ID'),
                  ),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: _mobileNumberController,
                    decoration: InputDecoration(labelText: 'Mobile Number'),
                    keyboardType: TextInputType.phone,
                  ),
                  DropdownButton<String>(
                    value: _selectedUserType,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _selectedUserType = newValue;
                      }
                    },
                    items: UserTypes.usertype
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _addUser(
                    _institutionalIdController.text,
                    _nameController.text,
                    _mobileNumberController.text,
                    _selectedUserType,
                  );
                  Navigator.pop(context);
                },
                child: Text('Add User'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show Update User Dialog
  void _showUpdateDialog(
      String docId, String name, String mobileNumber, String userType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final _nameController = TextEditingController(text: name);
        final _mobileNumberController =
            TextEditingController(text: mobileNumber);
        String _selectedUserType = userType;

        return Theme(
            data: ThemeData(
              canvasColor: Colors
                  .white, // Forces the dropdown menu background color to white
            ),
            child: AlertDialog(
              title: Text('Update User'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: _mobileNumberController,
                      decoration: InputDecoration(labelText: 'Mobile Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    DropdownButton<String>(
                      value: _selectedUserType,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _selectedUserType = newValue;
                        }
                      },
                      items: UserTypes.usertype
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.blue)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateUser(
                      docId,
                      _nameController.text,
                      _mobileNumberController.text,
                      _selectedUserType,
                    );
                    Navigator.pop(context);
                  },
                  child:
                      Text('Update User', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ));
      },
    );
  }

  // Show Delete Confirmation Dialog
  void _showDeleteConfirmationDialog(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
            data: ThemeData(
              canvasColor: Colors
                  .white, // Forces the dropdown menu background color to white
            ),
            child: AlertDialog(
              title: Text('Delete User'),
              content: Text('Do you want to delete this user?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.blue)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _deleteUser(docId);
                    Navigator.pop(context);
                  },
                  child: Text('Delete', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              var createdAt = user['createdAt']?.toDate();

              // Cast data to Map<String, dynamic> and check for the 'isRegistered' and 'registrationTimestamp' fields
              var userData = user.data() as Map<String, dynamic>;
              var isRegistered = userData.containsKey('isRegistered')
                  ? userData['isRegistered']
                  : false;
              var registrationTimestamp =
                  userData.containsKey('registrationTimestamp')
                      ? userData['registrationTimestamp']?.toDate()
                      : null;

              return Card(
                margin: EdgeInsets.all(10),
                elevation: 5,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      isExpanded = !isExpanded;
                      selectedUserId = user.id;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              user['name'],
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _showUpdateDialog(
                                      user.id,
                                      user['name'],
                                      user['mobileNumber'],
                                      user['userType']),
                                  icon: Icon(Icons.edit,
                                      color: Colors.green), // Green pencil icon
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _showDeleteConfirmationDialog(user.id),
                                  icon: Icon(Icons.delete,
                                      color: Colors.red), // Red delete icon
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text('Institutional ID: ${user['institutionalId']}'),
                        Text('User Type: ${user['userType']}'),
                        if (isExpanded) ...[
                          SizedBox(height: 10),
                          Text('Mobile: ${user['mobileNumber']}'),
                          Text(
                              'Created At: ${createdAt?.toLocal().toString() ?? 'N/A'}'),
                          Text(
                              'Registration Timestamp: ${registrationTimestamp?.toLocal().toString() ?? 'N/A'}'),
                          Text('Is Registered: ${isRegistered ? 'Yes' : 'No'}'),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
