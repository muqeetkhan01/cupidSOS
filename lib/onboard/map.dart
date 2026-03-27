import 'package:cupid_app/config/flow.dart';
import 'package:cupid_app/config/app_theme.dart';
import 'package:cupid_app/onboard/looking_for_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:place_picker_google/place_picker_google.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../config/colors.dart';
import '../../widgets/button_widget.dart';
import '../../widgets/text_widget.dart';

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
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: CupidColors.scaffold(context),
            primaryColor: const Color(0xFFFF6F7D),
            colorScheme: Theme.of(context).brightness == Brightness.dark
                ? const ColorScheme.dark(
                    primary: Color(0xFFFF6F7D),
                    secondary: Color(0xFFFF6F7D),
                  )
                : const ColorScheme.light(
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
    final latLng = pickedLocation?.latLng ??
        LatLng(
          flow.latitude.value ?? _initialLatLng.latitude,
          flow.longitude.value ?? _initialLatLng.longitude,
        );
    final label = addressController.text.trim();

    if (label.isEmpty) return;

    flow.locationLabel.value = label;
    flow.latitude.value = latLng.latitude;
    flow.longitude.value = latLng.longitude;

    await flow.saveOnboardingProgress();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LookingForScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = addressController.text.isNotEmpty &&
        (pickedLocation?.latLng != null ||
            (flow.latitude.value != null && flow.longitude.value != null));

    return Scaffold(
      backgroundColor: CupidColors.scaffold(context),
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
                    text: '12 of 19',
                    size: 14,
                    color: null,
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
                color: null,
              ),
              SizedBox(height: 3.h),
              GestureDetector(
                onTap: _pickLocation,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
                  decoration: BoxDecoration(
                    color: CupidColors.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CupidColors.border(context)),
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
                              ? CupidColors.textSecondary(context)
                              : CupidColors.textPrimary(context),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: CupidColors.textSecondary(context),
                      ),
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
                backgroundColor: CupidColors.border(context),
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
