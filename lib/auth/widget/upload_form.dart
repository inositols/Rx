import 'package:flutter/material.dart';

List<Widget> buildUploadForm(
  String? csvData,
  String? csvFileName,
  TextEditingController levelController,
  TextEditingController universityController,
  Function() pickCSVFile,
  Function() uploadStudents,
) {
  return [
    Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CSV Format Requirements:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Column 1: S/N (Serial Number)\n'
              '• Column 2: Full Name\n'
              '• Column 3: Registration Number (YYYY/NNNNNN)\n'
              '• No header row\n'
              '• Example: 1,John Doe,2023/123456',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 20),

    // CSV File picker
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            csvData != null ? Icons.check_circle : Icons.upload_file,
            size: 48,
            color: csvData != null ? Colors.green : Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            csvData != null ? 'File Selected: $csvFileName' : 'Select CSV File',
            style: TextStyle(
              color: csvData != null ? Colors.green : Colors.grey,
              fontWeight: csvData != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: pickCSVFile,
            icon: const Icon(Icons.folder_open),
            label: Text(csvData != null ? 'Change File' : 'Browse Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),

    // Level dropdown
    DropdownButtonFormField<String>(
      value: levelController.text.isEmpty ? null : levelController.text,
      decoration: const InputDecoration(
        labelText: 'Student Level',
        prefixIcon: Icon(Icons.school),
        border: OutlineInputBorder(),
      ),
      items: ['100', '200', '300', '400', '500', 'Postgraduate'].map((level) {
        return DropdownMenuItem(
          value: level,
          child: Text('Level $level'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          levelController.text = value;
        }
      },
    ),
    const SizedBox(height: 16),

    // University text field
    TextField(
      controller: universityController,
      decoration: const InputDecoration(
        labelText: 'University Name',
        hintText: 'University of Nigeria, Nsukka',
        prefixIcon: Icon(Icons.account_balance),
        border: OutlineInputBorder(),
      ),
    ),
    const SizedBox(height: 30),

    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: uploadStudents,
      child: const Text('Upload Students', style: TextStyle(fontSize: 16)),
    ),
  ];
}
