import 'package:cupid_app/onboard/preferences_screen.dart';
import 'package:flutter/material.dart';
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
  GoogleMapController? _mapController;

  LocationResult? pickedLocation;

  final TextEditingController addressController = TextEditingController();

  LatLng _initialLatLng = const LatLng(40.7128, -74.0060); // NYC default

  /// 📍 OPEN PLACE PICKER
  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        builder: (context) => Theme(
          data: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            primaryColor: Color(0xFFFF6F7D),
            colorScheme: ColorScheme.light(
              primary: Color(0xFFFF6F7D),
              secondary: Color(0xFFFF6F7D),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFFFF6F7D),
              foregroundColor: Colors.white,
              elevation: 0,
              titleTextStyle: const TextStyle(
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
              // enableNearbyPlaces: false,
              // initialPosition: _initialLatLng,
              // useCurrentLocation: true,
              onPlacePicked: (place) {
                Navigator.of(context).pop(place);
              },
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        pickedLocation = result;
        addressController.text = result.formattedAddress ?? "";
        _initialLatLng = LatLng(
          result.latLng!.latitude,
          result.latLng!.longitude,
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_initialLatLng),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4.h),

              /// Title
              const TextWidget(
                text: "Where are you located?",
                size: 26,
                weight: FontWeight.w700,
              ),

              SizedBox(height: 1.5.h),

              /// Subtitle
              TextWidget(
                text:
                    "We'll use your city to find nearby matches—never your exact address.",
                size: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),

              SizedBox(height: 4.h),

              /// 🗺️ GOOGLE MAP
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _initialLatLng,
                          zoom: 13,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        onTap: (_) => _pickLocation(),
                      ),
                    ),

                    /// City pill
                    if (pickedLocation != null)
                      Positioned(
                        top: 50.h,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 1.4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: TextWidget(
                              text:
                                  pickedLocation!.country!.longName!.isNotEmpty
                                      ? pickedLocation!.country!.longName!
                                      : pickedLocation!.formattedAddress ?? "",
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    /// Target button
                    Positioned(
                      bottom: 2.5.h,
                      right: 3.w,
                      child: GestureDetector(
                        onTap: _pickLocation,
                        child: Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              /// Continue
              ButtonWidget(
                text: "Continue",
                height: 7,
                radius: 36,
                variant: pickedLocation != null
                    ? ButtonVariant.gradient
                    : ButtonVariant.solid,
                backgroundColor: Colors.grey.shade300,
                gradient: const [
                  Color(0xFFFF6F7D),
                  Color(0xFFD86BCF),
                ],
                onTap: pickedLocation != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PreferencesScreen(),
                          ),
                        );
                      }
                    : () {},
              ),

              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }
}
