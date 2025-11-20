import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../../services/toast_service.dart';

class ContactController extends GetxController {
  late final contactMethods = [
    ContactMethod(
      icon: Icons.email,
      title: "Email Us",
      subtitle: "sales@siaratechnology.com",
      action: () => launchUrl('mailto:sales@siaratechnology.com'),
    ),
    ContactMethod(
      icon: Icons.email,
      title: "General Inquiry",
      subtitle: "Get in touch via email",
      action: () => launchUrl('mailto:sales@siaratechnology.com'),
    ),
    ContactMethod(
      icon: Icons.language,
      title: "Global Reach",
      subtitle: "International Clients - UAE, Africa, Bangladesh",
      action: () => ApptoastUtils.showInfo('Serving clients globally'),
    ),
  ];

  final socialMedia = [
    SocialMedia(
        icon: Icons.facebook_outlined,
        url: 'https://facebook.com/siaratechnology'),
    SocialMedia(
        icon: FontAwesomeIcons.youtube,
        url: 'https://www.youtube.com/@SiaraTechnology'),
    SocialMedia(
        icon: FontAwesomeIcons.linkedinIn,
        url: 'https://www.linkedin.com/company/siara-technology/'),
  ];

  final branches = [
    BranchInfo(
      name: "Noida (Headquarters)",
      region: "Delhi NCR",
      address:
          "C-55, Sector 2, Near Sector 15 Metro Station, Noida, Uttar Pradesh 201301",
      coordinates: "28.582534,77.3143583",
    ),
    BranchInfo(
      name: "Kolkata",
      region: "Eastern India",
      address: "Kolkata, West Bengal",
      coordinates: "22.655149,88.340553",
    ),
    BranchInfo(
      name: "Dubai",
      region: "United Arab Emirates",
      address: "Coming Soon - International Expansion",
      coordinates: "25.276987,55.296249",
    ),
  ];

  Future<void> launchUrl(String url) async {
    try {
      if (await url_launcher.canLaunchUrl(Uri.parse(url))) {
        await url_launcher.launchUrl(Uri.parse(url));
      }
    } catch (e) {
      ApptoastUtils.showError('Could not launch $url');
    }
  }

  void openNoidaMaps() {
    final url =
        "https://maps.google.com/?q=C-55+Sector+2+Near+Sector+15+Metro+Station+Noida+Uttar+Pradesh+201301";
    launchUrl(url);
  }

  void openKolkataMaps() {
    final url =
        "https://www.google.com/maps/place/Bally,+Howrah,+West+Bengal/@22.6496663,88.3383647,21z/data=!4m15!1m8!3m7!1s0x39f89d1841fda7e5:0x677bb00b2e81db80!2sBally,+Howrah,+West+Bengal!3b1!8m2!3d22.6496657!4d88.3386447!16s%2Fm%2F055mhsb!3m5!1s0x39f89d1841fda7e5:0x677bb00b2e81db80!8m2!3d22.6496657!4d88.3386447!16s%2Fm%2F055mhsb?entry=ttu&g_ep=EgoyMDI1MTExNy4wIKXMDSoASAFQAw%3D%3D";
    launchUrl(url);
  }

  void openDubaiMaps() {
    final url = "https://maps.google.com/?q=Dubai+United+Arab+Emirates";
    launchUrl(url);
  }
}

class ContactMethod {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback action;

  ContactMethod({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });
}

class BranchInfo {
  final String name;
  final String region;
  final String address;
  final String coordinates;

  BranchInfo({
    required this.name,
    required this.region,
    required this.address,
    required this.coordinates,
  });
}

class SocialMedia {
  final IconData icon;
  final String url;

  SocialMedia({
    required this.icon,
    required this.url,
  });
}
