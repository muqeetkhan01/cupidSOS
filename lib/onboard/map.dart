import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/onboard/work_education_hometown_screen.dart';
import 'package:cupid_app/onboard/preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:place_picker_google/place_picker_google.dart';

import '../../widgets/text_widget.dart';
import '../../widgets/button_widget.dart';
import '../../config/colors.dart';

class LocationQuestionScreen extends StatefulWidget {
  const LocationQuestionScreen({super.key});

  @override
  State<LocationQuestionScreen> createState() => _LocationQuestionScreenState();
}

class _LocationQuestionScreenState extends State<LocationQuestionScreen> {
  final flow = Get.find<AppFlowController>();

  GoogleMapController? _mapController;
  LocationResult? pickedLocation;

  final TextEditingController addressController = TextEditingController();

  LatLng _initialLatLng = const LatLng(40.7128, -74.0060); // NYC default

  @override
  void initState() {
    super.initState();

    // ✅ Prefill from saved progress (resume support)
    final lat = flow.latitude.value;
    final lng = flow.longitude.value;
    final label = flow.locationLabel.value;

    if (lat != null && lng != null) {
      _initialLatLng = LatLng(lat, lng);
    }
    if (label != null && label.trim().isNotEmpty) {
      addressController.text = label;
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        builder: (context) => Theme(
          data: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            primaryColor: const Color(0xFFFF6F7D),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6F7D),
              secondary: Color(0xFFFF6F7D),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFF6F7D),
              foregroundColor: Colors.white,
              elevation: 0,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Pick Location"),
              centerTitle: true,
            ),
            body: PlacePicker(
              apiKey: 'AIzaSyDLRt7r36ovJdIhsn4GeUV267P_taJaWpY',
              onPlacePicked: (place) => Navigator.of(context).pop(place),
            ),
          ),
        ),
      ),
    );

    if (result != null && result.latLng != null) {
      setState(() {
        pickedLocation = result;
        addressController.text = result.formattedAddress ?? "";
        _initialLatLng = LatLng(
          result.latLng!.latitude,
          result.latLng!.longitude,
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_initialLatLng, 12),
      );
    }
  }

  Future<void> _continue() async {
    final latLng = pickedLocation?.latLng;
    final label = addressController.text.trim();

    if (latLng == null || label.isEmpty) return;

    flow.locationLabel.value = label;
    flow.latitude.value = latLng.latitude;
    flow.longitude.value = latLng.longitude;

    await flow.saveOnboardingProgress();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkEducationHometownScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue =
        (pickedLocation?.latLng != null) && addressController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const TextWidget(
                    text: 'Step 6 of 10',
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              TextWidget(
                text: "Where are you located?",
                size: 18.sp,
                weight: FontWeight.w500,
              ),
              SizedBox(height: 1.h),
              const TextWidget(
                text: "We’ll use this to show you better matches near you.",
                size: 15,
                color: Colors.grey,
              ),
              SizedBox(height: 3.h),
              GestureDetector(
                onTap: _pickLocation,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: TextWidget(
                          text: addressController.text.isEmpty
                              ? "Tap to select location"
                              : addressController.text,
                          size: 15,
                          color: addressController.text.isEmpty
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  height: 32.h,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _initialLatLng,
                      zoom: 11,
                    ),
                    onMapCreated: (c) => _mapController = c,
                    markers: {
                      Marker(
                        markerId: const MarkerId("picked"),
                        position: _initialLatLng,
                      ),
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              ButtonWidget(
                text: "Continue",
                height: 7,
                radius: 36,
                variant:
                    canContinue ? ButtonVariant.gradient : ButtonVariant.solid,
                backgroundColor: Colors.grey.shade300,
                gradient: const [Color(0xFFFF6F7D), Color(0xFFD86BCF)],
                onTap: canContinue ? _continue : () {},
              ),
              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }
}
