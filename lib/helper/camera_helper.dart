import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_recognition/helper/tensor_flow_lite_helper.dart';

class CameraHelper{
  static CameraController cameraController;
  static bool isDetecting = false;
  static CameraLensDirection _cameraLensDirection = CameraLensDirection.back;
  static Future<void> initializeControllerFuture;

   static Future<CameraDescription> _getCameraBasedOnLenDirection(CameraLensDirection cameraLensDirection) async {
    return await availableCameras().then(
      (List<CameraDescription> cameras) => cameras.firstWhere(
        (CameraDescription camera) => camera.lensDirection == cameraLensDirection,
      ),
    );
  }

  static void initializeCamera() async{
    print("****** Initializing Camera...");

    cameraController = CameraController(
      await _getCameraBasedOnLenDirection(_cameraLensDirection),
      defaultTargetPlatform == TargetPlatform.iOS ? ResolutionPreset.low : ResolutionPreset.high,
      enableAudio: false
    );

    initializeControllerFuture = cameraController.initialize().then((value){
      print("****** Camera initialized, starting camera stream...");

      cameraController.startImageStream((CameraImage cameraImage){
        if(!TenserFlowLiteHelper.lodadedModel) return;
        if(isDetecting) return;
        isDetecting = true;

        try {
          TenserFlowLiteHelper.classifyImage(cameraImage);
        } catch (e) {
          print(e);
        }
      });
    });
  }
}