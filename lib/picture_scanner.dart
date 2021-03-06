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

final animals = [
  {"title": "Elephant", "class": "Mammal"},
  {"title": "Dog", "class": "Mammal"},
  {"title": "Cat", "class": "Mammal"},
  {"title": "Snake", "class": "Reptile"},
  {"title": "Bird", "class": "Also a Bird!"},
  {"title": "Horse", "class": "Mammal"},
  {"title": "Frog", "class": "Amphibian"},
  {"title": "Giraffe", "class": "Mammal"},
  {"title": "Turtle", "class": "Reptile"},
  {"title": "Rabbit", "class": "Mammal"},
  {"title": "Tiger", "class": "Mammal"},
  {"title": "Fish", "class": "Also a Fish"},
  {"title": "Zebra", "class": "Mammal"}

];

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

    for (var animal in animals) {
      if (animal['title'] == animalName) {
        animalClass = animal['class'];
      }
    }

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
          fit: BoxFit.cover,
        ),
      ),
      child: _imageSize == null || _scanResults == null
          ? Center(
              child: Text(

                'Scanning your animal...',
                style: TextStyle(backgroundColor: Colors.lightGreen[300].withOpacity(0.6),
                  color: Colors.white,
                  fontSize: 30.0,
                ),
              ),
            )
          : Padding(
        padding: EdgeInsets.only(top: 240.0),
        child: Text("Your animal: " + animalName + "\n" + "Classification: " + animalClass, textAlign: TextAlign.center, style: TextStyle(fontSize: 30, color: Colors.white, backgroundColor: Colors.lightGreen[300].withOpacity(0.6)),),
      )
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
          ? Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              // Padding(padding: EdgeInsets.only(bottom: 70.0), child: Image.asset('images/logo.png'),),

              Image.asset('images/logo.png'),
              Padding(padding: EdgeInsets.only(bottom: 140.0), child: Text('Select an image of an animal to begin!', style: TextStyle(fontSize: 20))),

              // Text('Select an image of an animal to begin!', style: TextStyle(fontSize: 20))
            ],
          ))
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
