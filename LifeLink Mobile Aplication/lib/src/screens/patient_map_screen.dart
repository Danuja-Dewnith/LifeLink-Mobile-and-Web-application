import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'patient_alerts_screen.dart';
import 'Patient_profile_screen.dart';
import 'donor_dash.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart' hide ProfileScreen;
import 'donate_screen.dart';
import 'patient_dashboard_screen.dart';
import 'my_requests_screen.dart';

class PatientMapScreen extends StatefulWidget {
  const PatientMapScreen({super.key});

  @override
  State<PatientMapScreen> createState() => _PatientMapScreenState();
}

class _PatientMapScreenState extends State<PatientMapScreen> {
  int _selectedNavIndex = 1; // Map is index 1

  GoogleMapController? _mapController;

  LatLng _currentPosition = const LatLng(7.2085, 79.8736);

  final Set<Marker> _markers = {};

  final TextEditingController _searchController = TextEditingController();

  bool _isLoadingLocation = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadRealHospitalMarkers();
    _getCurrentLocation();
  }

  // ==================== 25+ REAL HOSPITALS ACROSS SRI LANKA ====================
  void _loadRealHospitalMarkers() {
    setState(() {
      _markers.addAll({
        Marker(
          markerId: const MarkerId('national_hospital_colombo'),
          position: const LatLng(6.9191, 79.8680),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'National Hospital of Sri Lanka',
            snippet: 'Largest Hospital • Colombo',
          ),
        ),
        Marker(
          markerId: const MarkerId('lanka_hospitals'),
          position: const LatLng(6.8870, 79.8720),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Lanka Hospitals',
            snippet: 'Private Multi-Specialty • Colombo',
          ),
        ),
        Marker(
          markerId: const MarkerId('nawaloka_colombo'),
          position: const LatLng(6.9207, 79.8536),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Nawaloka Hospital Colombo'),
        ),
        Marker(
          markerId: const MarkerId('asiri_colombo'),
          position: const LatLng(6.9125, 79.8700),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Asiri Hospital Colombo'),
        ),
        Marker(
          markerId: const MarkerId('negombo_general'),
          position: const LatLng(7.2125, 79.8484),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Negombo District General Hospital',
            snippet: 'Main Public Hospital • Blood Bank',
          ),
        ),
        Marker(
          markerId: const MarkerId('nawaloka_negombo'),
          position: const LatLng(7.2093, 79.8497),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Nawaloka Hospital Negombo',
            snippet: 'Private • 24/7 Emergency',
          ),
        ),
        Marker(
          markerId: const MarkerId('kandy_teaching'),
          position: const LatLng(7.2863, 80.6316),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Teaching Hospital Kandy'),
        ),
        Marker(
          markerId: const MarkerId('karapitiya'),
          position: const LatLng(6.0530, 80.2200),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow:
              const InfoWindow(title: 'Teaching Hospital Karapitiya - Galle'),
        ),
        Marker(
          markerId: const MarkerId('jaffna_teaching'),
          position: const LatLng(9.6615, 80.0255),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Teaching Hospital Jaffna'),
        ),
        Marker(
          markerId: const MarkerId('batticaloa_teaching'),
          position: const LatLng(7.7170, 81.7000),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Teaching Hospital Batticaloa'),
        ),
        Marker(
          markerId: const MarkerId('anuradhapura'),
          position: const LatLng(8.3114, 80.4037),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Teaching Hospital Anuradhapura'),
        ),
        Marker(
          markerId: const MarkerId('kurunegala'),
          position: const LatLng(7.4867, 80.3650),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Teaching Hospital Kurunegala'),
        ),
        Marker(
          markerId: const MarkerId('ratnapura'),
          position: const LatLng(6.6828, 80.3992),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow:
              const InfoWindow(title: 'Provincial General Hospital Ratnapura'),
        ),
        Marker(
          markerId: const MarkerId('badulla'),
          position: const LatLng(6.9934, 81.0550),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow:
              const InfoWindow(title: 'Provincial General Hospital Badulla'),
        ),
        Marker(
          markerId: const MarkerId('matara'),
          position: const LatLng(5.9485, 80.5353),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow:
              const InfoWindow(title: 'District General Hospital Matara'),
        ),
        Marker(
          markerId: const MarkerId('hambantota'),
          position: const LatLng(6.1240, 81.1180),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow:
              const InfoWindow(title: 'District General Hospital Hambantota'),
        ),
        Marker(
          markerId: const MarkerId('trincomalee'),
          position: const LatLng(8.5874, 81.2152),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow:
              const InfoWindow(title: 'District General Hospital Trincomalee'),
        ),
        Marker(
          markerId: const MarkerId('polonnaruwa'),
          position: const LatLng(7.9390, 81.0000),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow:
              const InfoWindow(title: 'District General Hospital Polonnaruwa'),
        ),
        Marker(
          markerId: const MarkerId('vavuniya'),
          position: const LatLng(8.7514, 80.4980),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow:
              const InfoWindow(title: 'District General Hospital Vavuniya'),
        ),
        Marker(
          markerId: const MarkerId('kalutara'),
          position: const LatLng(6.5854, 79.9607),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow:
              const InfoWindow(title: 'District General Hospital Kalutara'),
        ),
        Marker(
          markerId: const MarkerId('gampaha'),
          position: const LatLng(7.0840, 79.9990),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow:
              const InfoWindow(title: 'District General Hospital Gampaha'),
        ),
        Marker(
          markerId: const MarkerId('peradeniya'),
          position: const LatLng(7.2690, 80.5950),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Peradeniya Teaching Hospital'),
        ),
      });
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      setState(() => _isLoadingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location permissions are permanently denied')),
      );
      setState(() => _isLoadingLocation = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLoadingLocation = false;

      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentPosition,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 15.0),
      );
    });
  }

  // ==================== IMPROVED SEARCH FUNCTIONALITY ====================
  Future<void> _performSearch() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    final String apiKey =
        "AIzaSyAqYCZjcf3LC449zgV-SGvs3t5bBL8XAis"; // ← Replace with your real Google API Key

    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$query&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        final LatLng searchedLocation =
            LatLng(location['lat'], location['lng']);

        setState(() {
          _markers.removeWhere((m) => m.markerId.value != 'current_location');

          _markers.add(
            Marker(
              markerId: const MarkerId('search_result'),
              position: searchedLocation,
              infoWindow: InfoWindow(title: query),
            ),
          );
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(searchedLocation, 16.0),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('No results found for "$query". Try a different name.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Search failed. Check your internet connection.')),
      );
    }

    setState(() => _isSearching = false);
    _searchController.clear();
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const PatientDashboardScreen()));
      return;
    }
    if (index == 1) return; // Already on map
    if (index == 3) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
      return;
    }
    if (index == 4) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      return;
    }
    setState(() => _selectedNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14.5,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (!_isLoadingLocation) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentPosition, 15.0),
                );
              }
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
          ),

          // ==================== SEARCH BAR ====================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.menu_rounded,
                          color: Color(0xFF455A64), size: 22),
                      const SizedBox(width: 12),
                      const Icon(Icons.search_rounded,
                          color: Color(0xFF2979FF), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'Search location or hospital',
                            hintStyle: TextStyle(
                              color: Color(0xFFB0BEC5),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                              color: Color(0xFF1A2340), fontSize: 14),
                          onSubmitted: (_) => _performSearch(),
                        ),
                      ),
                      Container(
                          width: 1, height: 24, color: const Color(0xFFE0E0E0)),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _performSearch,
                        child: _isSearching
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location_rounded,
                                color: Color(0xFF2979FF), size: 22),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Map Controls
          Positioned(
            right: 16,
            bottom: 100,
            child: _buildMapControls(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyRequestsScreen())),
        backgroundColor: const Color(0xFF2979FF),
        elevation: 4,
        shape: const CircleBorder(),
        child:
            const Icon(Icons.list_alt_rounded, color: Colors.white, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ==================== MAP CONTROLS ====================
  Widget _buildMapControls() {
    return Column(
      children: [
        _buildControlBtn(
            child: GestureDetector(
          onTap: () {
            _mapController?.animateCamera(
              CameraUpdate.zoomIn(),
            );
          },
          child:
              const Icon(Icons.add_rounded, color: Color(0xFF1A2340), size: 24),
        )),
        const SizedBox(height: 8),
        _buildControlBtn(
            child: GestureDetector(
          onTap: () {
            _mapController?.animateCamera(
              CameraUpdate.zoomOut(),
            );
          },
          child: const Icon(Icons.remove_rounded,
              color: Color(0xFF1A2340), size: 24),
        )),
        const SizedBox(height: 8),
        _buildControlBtn(
          child: GestureDetector(
            onTap: _getCurrentLocation,
            child: const Icon(Icons.my_location_rounded,
                color: Color(0xFF2979FF), size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildControlBtn({required Widget child}) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Center(child: child),
    );
  }

  // ==================== BOTTOM NAV BAR (Same as Dashboard) ====================
  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 14,
      shadowColor: Colors.black.withOpacity(0.10),
      notchMargin: 6,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
            _buildNavItem(icon: Icons.map_rounded, label: 'Map', index: 1),
            const SizedBox(width: 58),
            _buildNavItemWithBadge(
                icon: Icons.notifications_outlined, label: 'Alerts', index: 3),
            _buildNavItem(
                icon: Icons.person_outline_rounded, label: 'Profile', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool active = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5),
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color:
                    active ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5),
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool active = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: active
                      ? const Color(0xFF2979FF)
                      : const Color(0xFFB0BEC5),
                  size: 24,
                ),
                // Optional badge indicator - you can conditionally show this
                // based on unread notifications count
                Positioned(
                  top: -2,
                  right: -3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color:
                    active ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5),
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
