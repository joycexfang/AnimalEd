// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'detector_painters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String animalName;
String animalClass;

class PictureScanner extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PictureScannerState();
}

class _PictureScannerState extends State<PictureScanner> {
  File _imageFile;
  Size _imageSize;
  dynamic _scanResults;
  Detector _currentDetector = Detector.text;
  final ImageLabeler _imageLabeler = FirebaseVision.instance.imageLabeler();
  final ImagePicker _picker = ImagePicker();

  Future<void> _getAndScanImage() async {
    setState(() {
      _imageFile = null;
      _imageSize = null;
    });

    final PickedFile pickedImage =
        await _picker.getImage(source: ImageSource.gallery);
    final File imageFile = File(pickedImage.path);

    if (imageFile != null) {
      _getImageSize(imageFile);
      _scanImage(imageFile);
    }

    setState(() {
      _imageFile = imageFile;
    });
  }

  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();

    final Image image = Image.file(imageFile);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );

    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
    });
  }

  Future<void> _scanImage(File imageFile) async {
    setState(() {
      _scanResults = null;
    });

    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFile(imageFile);

    dynamic results;

    results = await _imageLabeler.processImage(visionImage);

    for (ImageLabel label in results) {
      animalName = label.text;
      break;
    }

    animalClass = "Hello";

    setState(() {
      _scanResults = results;
    });
  }

  CustomPaint _buildResults(Size imageSize, dynamic results) {
    CustomPainter painter;

    painter = LabelDetectorPainter(_imageSize, results);

    return CustomPaint(
      painter: painter,
    );
  }

  // Returns Animal's Classification
  // Future<void> getAnimalClass() async {
    // var result = await Firestore.instance
    //     .collection("animals")
    //     .where("Title", isEqualTo: animalName)
    //     .getDocuments();
    // result.documents.forEach((res) {
    //   animalClass = "hello";
    // });
  // }

  Widget _buildImage() {
    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Image.file(_imageFile).image,
          fit: BoxFit.fill,
        ),
      ),
      child: _imageSize == null || _scanResults == null
          ? const Center(
              child: Text(

                'Scanning your animal...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30.0,
                ),
              ),
            )
          : Text(animalName + "\n" + animalClass, style: TextStyle(fontSize: 30, color: Colors.white),),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AnimalEd'),
        backgroundColor: Colors.lightGreen[300],
      ),
      body: _imageFile == null
          ? const Center(child: Text('Select an image of an animal to begin!!', style: TextStyle(fontSize: 20)))
          : _buildImage(),
      floatingActionButton: FloatingActionButton(
        onPressed: _getAndScanImage,
        tooltip: 'Pick Image',
        child: const Icon(Icons.add_a_photo),
        backgroundColor: Colors.lightGreen[300],
      ),
    );
  }

  @override
  void dispose() {
    _imageLabeler.close();
    super.dispose();
  }
}
