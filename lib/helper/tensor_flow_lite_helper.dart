import 'dart:async';

import 'package:camera/camera.dart';
import 'package:image_recognition/model/result.dart';
import 'package:tflite/tflite.dart';

class TenserFlowLiteHelper{
  static StreamController<List<Result>> tfLiteResultsController = StreamController.broadcast();
  static List<Result> _outputs = List();
  static var lodadedModel = false;

  static Future<String> loadModel() async{
    print("****** Loading Model....");
    return Tflite.loadModel(model: "assets/model.tflite", labels: "assets/labels.txt");
  }

  static classifyImage(CameraImage cameraImage) async{
    await Tflite.runModelOnFrame(bytesList: cameraImage.planes.map((plane){
      return plane.bytes;
    }).toList(),
    numResults: 5).then((values){
      if(values.isNotEmpty){
        print("****** Results loaded ${values.length}");

        _outputs.clear();

        values.forEach((element) {
          Result resultToAdd = new Result(element['confidence'], element['index'], element['label']);
          _outputs.add(
            resultToAdd
          );
          print("****** ${resultToAdd.toString()}");
        });
      }
      //Sort by confidence
      _outputs.sort((a, b)=> a.confidence.compareTo(b.confidence));

      //Send to the controller the outputs from the analyzis
      tfLiteResultsController.add(_outputs);
    });
  }

  static void disposeModel(){
    Tflite.close();
    tfLiteResultsController.close();
  }

}

