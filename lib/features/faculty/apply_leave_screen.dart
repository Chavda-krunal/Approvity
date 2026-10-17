import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add 'intl: ^0.19.0' to your pubspec.yaml if you haven't!

import '../../core/constants/app_colors.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  final User? currentUser = FirebaseAuth.instance.currentUser;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Prevent picking past dates
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Reset end date if it is now before the new start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      _showSnackBar("Please select both start and end dates", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Fetch the faculty's name from the database using their UID
      String facultyName = "Unknown Faculty";
      final facultyQuery = await _dbRef.child('faculty')
          .orderByChild('uid')
          .equalTo(currentUser?.uid)
          .get();

      if (facultyQuery.exists) {
        // Extract the name from the first matching record
        final data = facultyQuery.value as Map<dynamic, dynamic>;
        facultyName = data.values.first['name'] ?? facultyName;
      }

      // 2. Generate a unique ID for the new leave request
      final newRequestRef = _dbRef.child('leave_requests').push();

      // 3. Format dates for readability
      final dateFormat = DateFormat('MMM dd, yyyy');

      // 4. Save to Realtime Database
      await newRequestRef.set({
        'uid': currentUser?.uid,
        'facultyName': facultyName, // Saving name here makes it easier for HOD to read
        'startDate': dateFormat.format(_startDate!),
        'endDate': dateFormat.format(_endDate!),
        'reason': _reasonController.text.trim(),
        'status': 'pending', // Default status
        'createdAt': ServerValue.timestamp,
      });

      if (mounted) {
        _showSnackBar("Leave request submitted successfully!", Colors.green);
        Navigator.pop(context); // Go back to the dashboard
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error submitting request: $e", Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Apply for Leave'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Leave Details",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 24),

                // Start Date Picker
                _buildDatePicker(
                  label: "Start Date",
                  value: _startDate != null ? dateFormat.format(_startDate!) : "Select Date",
                  onTap: () => _selectDate(context, true),
                ),
                const SizedBox(height: 16),

                // End Date Picker
                _buildDatePicker(
                  label: "End Date",
                  value: _endDate != null ? dateFormat.format(_endDate!) : "Select Date",
                  onTap: () {
                    if (_startDate == null) {
                      _showSnackBar("Please select a Start Date first", Colors.orange);
                      return;
                    }
                    _selectDate(context, false);
                  },
                ),
                const SizedBox(height: 24),

                // Reason Text Field
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Reason for Leave",
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a reason';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Submit Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
                    : ElevatedButton(
                  onPressed: _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Submit Request",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({required String label, required String value, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 16)),
                const Icon(Icons.calendar_month, color: AppColors.primaryPurple),
              ],
            ),
          ),
        ),
      ],
    );
  }
}