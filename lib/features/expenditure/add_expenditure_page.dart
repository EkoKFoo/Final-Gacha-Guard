import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddExpenditurePage extends StatefulWidget {
  const AddExpenditurePage({Key? key}) : super(key: key);

  @override
  State<AddExpenditurePage> createState() => _AddExpenditurePageState();
}

class _AddExpenditurePageState extends State<AddExpenditurePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isProcessing = false;
  String? _lastProcessedFileName;

  final List<String> _categories = [
    'Battle Pass',
    'Monthly Pass',
    'Premium Currency',
    'Gacha Pulls',
    'Cosmetics',
    'Other',
  ];

  final ImagePicker _picker = ImagePicker();
  final textRecognizer = TextRecognizer();

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        await _processImageFile(File(image.path), image.name);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await _processImageFile(File(image.path), image.name);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'heif'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        
        await _processImageFile(file, fileName);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick file: $e');
    }
  }

  void _showFileSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Choose File (Image)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processImageFile(File imageFile, String fileName) async {
    setState(() {
      _isProcessing = true;
      _lastProcessedFileName = fileName;
    });

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      _extractReceiptData(recognizedText.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt processed from $fileName! Please verify the extracted information.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to process receipt: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _extractReceiptData(String text) {
    final lines = text.split('\n');
    final lowercaseText = text.toLowerCase();
    
    // STRATEGY 1: Extract amounts with multiple patterns
    if (_amountController.text.isEmpty) {
      _extractAmount(lines, text);
    }

    // STRATEGY 2: Extract date with multiple formats
    _extractDate(lines, text);

    // STRATEGY 3: Extract time
    _extractTime(lines);

    // STRATEGY 4: Extract merchant with fuzzy matching
    if (_merchantController.text.isEmpty) {
      _extractMerchant(lines, text, lowercaseText);
    }

    // STRATEGY 5: Extract title/details/description
    if (_detailsController.text.isEmpty) {
      _extractDetails(lines, text, lowercaseText);
    }

    // STRATEGY 6: Auto-detect category
    if (_selectedCategory == null) {
      _detectCategory(lowercaseText);
    }

    // Auto-generate title if empty (for dashboard convenience)
    if (_titleController.text.isEmpty) {
      if (_merchantController.text.isNotEmpty) {
        _titleController.text = _merchantController.text;
      } else if (_detailsController.text.isNotEmpty) {
        _titleController.text = _detailsController.text.length > 30 
            ? _detailsController.text.substring(0, 30) 
            : _detailsController.text;
      } else {
        _titleController.text = 'Payment';
      }
    }

    // Auto-generate details if empty
    if (_detailsController.text.isEmpty) {
      _detailsController.text = _merchantController.text.isNotEmpty 
          ? 'Payment - ${_merchantController.text}' 
          : 'Payment';
    }

    setState(() {});
  }

  void _extractAmount(List<String> lines, String text) {
    final amounts = <double>[];
    
    // Pattern 1: Negative amounts (like -RM19.90)
    final negativeAmountRegex = RegExp(r'-\s*(?:RM|MYR|\$|USD|SGD|EUR|£)?\s*(\d+[.,]\d{2})', caseSensitive: false);
    
    // Pattern 2: Positive amounts with currency
    final currencyAmountRegex = RegExp(r'(?:RM|MYR|\$|USD|SGD|EUR|£)\s*(\d+[.,]\d{2,})', caseSensitive: false);
    
    // Pattern 3: Amounts in "Total" or "Amount" context
    final contextAmountRegex = RegExp(r'(?:total|amount|paid|price|cost|charge)[\s:]*(?:RM|MYR|\$|USD|SGD|EUR|£)?\s*(\d+[.,]\d{2,})', caseSensitive: false);
    
    // Pattern 4: Standalone numbers that look like money
    final standaloneAmountRegex = RegExp(r'\b(\d+[.,]\d{2})\b');
    
    for (var line in lines) {
      // Check negative amounts first (highest priority)
      var matches = negativeAmountRegex.allMatches(line);
      for (var match in matches) {
        final amountStr = match.group(1)?.replaceAll(',', '.');
        var amount = double.tryParse(amountStr ?? '');
        if (amount != null && amount > 0) {
          amounts.add(amount);
        }
      }
      
      // Check currency amounts
      matches = currencyAmountRegex.allMatches(line);
      for (var match in matches) {
        final amountStr = match.group(1)?.replaceAll(',', '.');
        var amount = double.tryParse(amountStr ?? '');
        if (amount != null && amount > 0) {
          amounts.add(amount);
        }
      }
      
      // Check context amounts
      matches = contextAmountRegex.allMatches(line);
      for (var match in matches) {
        final amountStr = match.group(1)?.replaceAll(',', '.');
        var amount = double.tryParse(amountStr ?? '');
        if (amount != null && amount > 0) {
          amounts.add(amount);
        }
      }
      
      // Check standalone amounts (lowest priority)
      if (amounts.isEmpty) {
        matches = standaloneAmountRegex.allMatches(line);
        for (var match in matches) {
          final amountStr = match.group(1)?.replaceAll(',', '.');
          var amount = double.tryParse(amountStr ?? '');
          if (amount != null && amount > 0 && amount < 100000) {
            amounts.add(amount);
          }
        }
      }
    }
    
    // Get the largest amount (usually the total)
    if (amounts.isNotEmpty) {
      amounts.sort((a, b) => b.compareTo(a));
      _amountController.text = amounts.first.toStringAsFixed(2);
    }
  }

  void _extractDate(List<String> lines, String text) {
    // Multiple date patterns
    final datePatterns = [
      RegExp(r'(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})'), // 28/10/2025, 28-10-2025
      RegExp(r'(\d{4}[-/]\d{1,2}[-/]\d{1,2})'), // 2025-10-28
      RegExp(r'(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4})', caseSensitive: false), // 28 Oct 2025
      RegExp(r'((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{2,4})', caseSensitive: false), // Oct 28, 2025
    ];
    
    for (var pattern in datePatterns) {
      for (var line in lines) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          try {
            final dateStr = match.group(0)!;
            DateTime? parsedDate;
            
            // Try different date formats
            final formats = [
              'dd/MM/yyyy', 'dd-MM-yyyy', 'yyyy-MM-dd', 'yyyy/MM/dd',
              'dd/MM/yy', 'dd-MM-yy', 'MM/dd/yyyy', 'MM-dd-yyyy',
              'dd MMM yyyy', 'dd MMMM yyyy', 'MMM dd, yyyy', 'MMMM dd, yyyy',
              'd MMM yyyy', 'd MMMM yyyy', 'MMM d, yyyy', 'MMMM d, yyyy',
            ];
            
            for (var format in formats) {
              try {
                parsedDate = DateFormat(format).parse(dateStr);
                break;
              } catch (_) {}
            }
            
            if (parsedDate != null) {
              setState(() {
                _selectedDate = parsedDate!;
              });
              return;
            }
          } catch (_) {}
        }
      }
    }
  }

  void _extractTime(List<String> lines) {
    final timeRegex = RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM|am|pm)?');
    
    for (var line in lines) {
      final match = timeRegex.firstMatch(line);
      if (match != null) {
        try {
          int hour = int.parse(match.group(1)!);
          int minute = int.parse(match.group(2)!);
          String? period = match.group(4)?.toUpperCase();
          
          if (period == 'PM' && hour < 12) {
            hour += 12;
          } else if (period == 'AM' && hour == 12) {
            hour = 0;
          }
          
          if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
            setState(() {
              _selectedTime = TimeOfDay(hour: hour, minute: minute);
            });
            return;
          }
        } catch (_) {}
      }
    }
  }

  void _extractMerchant(List<String> lines, String text, String lowercaseText) {
    // Fuzzy label patterns for merchant
    final merchantLabels = [
      'merchant', 'store', 'shop', 'vendor', 'seller', 'from', 
      'business', 'company', 'retailer', 'outlet'
    ];
    
    // Try labeled approach first
    for (var label in merchantLabels) {
      final labelRegex = RegExp('$label\\s*[:：]?\\s*([^\\n]+)', caseSensitive: false);
      final match = labelRegex.firstMatch(text);
      
      if (match != null) {
        final merchantName = match.group(1)?.trim();
        if (merchantName != null && 
            merchantName.isNotEmpty && 
            merchantName.length > 2 &&
            !merchantName.toLowerCase().contains('transaction') &&
            !merchantName.toLowerCase().contains('type')) {
          _merchantController.text = merchantName;
          return;
        }
      }
    }
    
    // Fallback: Look at first few non-empty lines (likely business name)
    final amountRegex = RegExp(r'[\d.,]+');
    for (var i = 0; i < lines.length && i < 8; i++) {
      final line = lines[i].trim();
      
      // Skip lines that are likely not merchant names
      if (line.isEmpty || line.length < 3 || line.length > 50) continue;
      if (line.contains(RegExp(r'\d{4}'))) continue; // Skip lines with years
      if (amountRegex.allMatches(line).length > 2) continue; // Skip lines with multiple numbers
      if (line.toLowerCase().contains('receipt')) continue;
      if (line.toLowerCase().contains('transaction')) continue;
      if (line.toLowerCase().contains('invoice')) continue;
      if (line.toLowerCase().contains('date')) continue;
      if (line.toLowerCase().contains('time')) continue;
      
      _merchantController.text = line;
      return;
    }
  }

  void _extractDetails(List<String> lines, String text, String lowercaseText) {
    // Fuzzy label patterns for details/description
    final detailLabels = [
      'payment details', 'details', 'description', 'item', 'product',
      'service', 'purchase', 'order', 'transaction details', 'info',
      'particulars', 'remarks', 'note', 'memo'
    ];
    
    for (var label in detailLabels) {
      final labelRegex = RegExp('$label\\s*[:：]?\\s*([^\\n]+)', caseSensitive: false);
      final match = labelRegex.firstMatch(text);
      
      if (match != null) {
        final details = match.group(1)?.trim();
        if (details != null && details.isNotEmpty && details.length > 3) {
          _detailsController.text = details;
          
          // Use details for title if title is empty (shortened version)
          if (_titleController.text.isEmpty) {
            _titleController.text = details.length > 30 
                ? details.substring(0, 30) 
                : details;
          }
          return;
        }
      }
    }
    
    // Fallback: Look for lines that seem like descriptions
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.length > 10 && 
          trimmed.length < 100 &&
          !trimmed.contains(RegExp(r'^\d+[.,]\d{2}$')) &&
          !trimmed.toLowerCase().contains('total') &&
          !trimmed.toLowerCase().contains('amount') &&
          !trimmed.toLowerCase().contains('date') &&
          !trimmed.toLowerCase().contains('time')) {
        _detailsController.text = trimmed;
        return;
      }
    }
  }

  void _detectCategory(String lowercaseText) {
    // Gaming-specific keywords
    if (lowercaseText.contains('battle pass') || 
        lowercaseText.contains('bp') && lowercaseText.contains('season')) {
      _selectedCategory = 'Battle Pass';
    } else if (lowercaseText.contains('monthly') || 
               lowercaseText.contains('subscription') ||
               lowercaseText.contains('welkin') ||
               lowercaseText.contains('express supply pass')) {
      _selectedCategory = 'Monthly Pass';
    } else if (lowercaseText.contains('crystal') || 
               lowercaseText.contains('gem') || 
               lowercaseText.contains('primogem') || 
               lowercaseText.contains('genesis') ||
               lowercaseText.contains('jade') ||
               lowercaseText.contains('stellar jade') ||
               lowercaseText.contains('oneiric') ||
               lowercaseText.contains('currency')) {
      _selectedCategory = 'Premium Currency';
    } else if (lowercaseText.contains('gacha') || 
               lowercaseText.contains('wish') || 
               lowercaseText.contains('pull') || 
               lowercaseText.contains('warp') ||
               lowercaseText.contains('banner') ||
               lowercaseText.contains('summon')) {
      _selectedCategory = 'Gacha Pulls';
    } else if (lowercaseText.contains('skin') || 
               lowercaseText.contains('cosmetic') || 
               lowercaseText.contains('outfit') ||
               lowercaseText.contains('costume') ||
               lowercaseText.contains('appearance')) {
      _selectedCategory = 'Cosmetics';
    } else if (lowercaseText.contains('star rail') || 
               lowercaseText.contains('genshin') ||
               lowercaseText.contains('honkai') ||
               lowercaseText.contains('hoyoverse') ||
               lowercaseText.contains('mihoyo') ||
               lowercaseText.contains('game') ||
               lowercaseText.contains('mobile game')) {
      _selectedCategory = 'Other';
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

void _saveTransaction() async {
  if (_formKey.currentState!.validate()) {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    // Combine date and time into a single DateTime
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Create a new Firestore document reference with auto-generated ID
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenditures')
        .doc();

    // Build transaction data
    final transaction = {
      'eid': docRef.id, // Firebase-generated ID
      'title': _titleController.text,
      'amount': double.parse(_amountController.text),
      'dateTime': dateTime,
      'category': _selectedCategory,
      'merchant': _merchantController.text,
      'details': _detailsController.text,
      'uid': user.uid, // Link to the logged-in user
    };

    // Save to Firestore
    await docRef.set(transaction);

    Navigator.of(context).pop(transaction);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Expenditure',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Receipt Scan Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF5B7FFF).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _lastProcessedFileName != null ? Icons.check_circle : Icons.document_scanner,
                          size: 48,
                          color: _lastProcessedFileName != null ? Colors.green : const Color(0xFF5B7FFF),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lastProcessedFileName != null 
                              ? 'Receipt Scanned' 
                              : 'Scan Receipt',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lastProcessedFileName != null 
                              ? 'Processed: $_lastProcessedFileName'
                              : 'Extract data from your receipt',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _showFileSourceDialog,
                          icon: const Icon(Icons.upload_file),
                          label: Text(_lastProcessedFileName != null ? 'Scan Another Receipt' : 'Scan Receipt'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5B7FFF),
                            side: const BorderSide(color: Color(0xFF5B7FFF)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildLabel('Title'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration('e.g., Battle Pass'),
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Details'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _detailsController,
                    maxLines: 3,
                    decoration: _inputDecoration('e.g., Genshin Impact Battle Pass'),
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter details' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Amount (RM)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration('0.00'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter an amount';
                      if (double.tryParse(value!) == null) return 'Please enter a valid number';
                      if (double.parse(value) <= 0) return 'Amount must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Category'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: _inputDecoration('Select a category'),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Date'),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('yyyy-MM-dd').format(_selectedDate),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const Icon(Icons.calendar_today, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Time'),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _selectTime(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedTime.format(context),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const Icon(Icons.access_time, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Merchant'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _merchantController,
                    decoration: _inputDecoration('e.g., Google Play Store'),
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter merchant' : null,
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7FFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add Transaction',
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing receipt...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF5B7FFF)),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    textRecognizer.close();
    super.dispose();
  }
}