import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_recognition/ui/detect_object_screen.dart';
import 'package:image_recognition/ui/detect_static_image_screen.dart';
import 'package:tflite/tflite.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: DasboardScreen(),
    );
  }
}

class DasboardScreen extends StatefulWidget {
  const DasboardScreen({Key key}) : super(key: key);

  @override
  _DasboardScreenState createState() => _DasboardScreenState();
}

class _DasboardScreenState extends State<DasboardScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          children: [
            TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DetectObjectScreen()),
                  );
                },
                child: Text("Detect Objects Screen")),
            TextButton(onPressed: () {
              Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TfliteHome()),
                  );
            }, child: Text("Detect Static objects Screen")),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraImage cameraImage;
  CameraController cameraController;
  String result = "";
  String streamingButtonText = "Stop";

  initCamera() {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value) {
      if (!mounted) return;
      setState(() {
        cameraController.startImageStream((imageStream) {
          cameraImage = imageStream;
          runModel();
        });
      });
    });
  }

  loadModel() async {
    await Tflite.loadModel(
        model: "assets/model.tflite", labels: "assets/labels.txt");
  }

  runModel() async {
    print("Run model");
    if (cameraImage != null) {
      var recognitions = await Tflite.runModelOnFrame(
          bytesList: cameraImage.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: cameraImage.height,
          imageWidth: cameraImage.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
          asynch: true);
      recognitions.forEach((element) {
        setState(() {
          result = element["label"];
          print(result);
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Face Mask Detector"),
        ),
        floatingActionButton: FloatingActionButton(
          child: Text(streamingButtonText),
          onPressed: () {
            print("object");
            if (!cameraController.value.isStreamingImages)
              setState(() {
                streamingButtonText = "Stop";
                cameraController.startImageStream((imageStream) {
                  cameraImage = imageStream;
                  runModel();
                });
              });
            else {
              setState(() {
                streamingButtonText = "Streaming";
              });
              cameraController.stopImageStream();
            }
          },
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                height: MediaQuery.of(context).size.height - 170,
                width: MediaQuery.of(context).size.width,
                child: !cameraController.value.isInitialized
                    ? Container()
                    : AspectRatio(
                        aspectRatio: cameraController.value.aspectRatio,
                        child: CameraPreview(cameraController),
                      ),
              ),
            ),
            Text(
              result,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
            )
          ],
        ),
      ),
    );
  }
}
