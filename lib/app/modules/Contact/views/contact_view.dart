import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/contact_controller.dart';

class ContactView extends GetView<ContactController> {
  const ContactView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          "Contact Us",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8.w),
        child: Column(
          children: [
            SizedBox(height: 15.h),
            const _ContactMethods(),
            SizedBox(height: 15.h),
            const _LocationSection(),
            SizedBox(height: 15.h),
            const _BusinessHoursSection(),
            SizedBox(height: 15.h),
            const _SocialMediaSection(),
            SizedBox(height: 15.h),
          ],
        ),
      ),
    );
  }
}

class _ContactMethods extends GetView<ContactController> {
  const _ContactMethods();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Get in Touch",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16.h),
            ...controller.contactMethods
                .map((method) => _ContactTile(method: method)),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final ContactMethod method;

  const _ContactTile({required this.method});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          method.icon,
          color: Theme.of(context).colorScheme.primary,
          size: 18.w,
        ),
      ),
      title: Text(
        method.title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        method.subtitle,
        style: TextStyle(
          fontSize: 12.sp,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14.w,
      ),
      onTap: method.action,
      contentPadding: EdgeInsets.symmetric(vertical: 8.h),
    );
  }
}

class _LocationSection extends GetView<ContactController> {
  const _LocationSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Our Offices",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16.h),

            // Noida HQ
            _OfficeSection(
              title: "Noida (Headquarters)",
              subtitle: "Delhi NCR",
              address:
                  "C-55, Sector 2, Near Sector 15 Metro Station, Noida, Uttar Pradesh 201301",
              onMapTap: () => controller.openNoidaMaps(),
            ),
            SizedBox(height: 20.h),

            // Kolkata Office
            _OfficeSection(
              title: "Kolkata",
              subtitle: "Eastern India",
              address: "Kolkata, West Bengal",
              onMapTap: () => controller.openKolkataMaps(),
            ),
            SizedBox(height: 20.h),

            // Dubai Office
            _OfficeSection(
              title: "Dubai",
              subtitle: "Coming Soon - United Arab Emirates",
              address: "International Expansion",
              onMapTap: () => controller.openDubaiMaps(),
              isComingSoon: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficeSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String address;
  final VoidCallback onMapTap;
  final bool isComingSoon;

  const _OfficeSection({
    required this.title,
    required this.subtitle,
    required this.address,
    required this.onMapTap,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.business,
              size: 16.w,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isComingSoon)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  "Coming Soon",
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.only(left: 28.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: Icons.location_on,
                text: address,
              ),
              if (!isComingSoon) ...[
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onMapTap,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 16.w),
                        SizedBox(width: 8.w),
                        Text(
                          "Open in Maps",
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BusinessHoursSection extends GetView<ContactController> {
  const _BusinessHoursSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Business Hours",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16.h),
            _BusinessHourRow(
              day: "Monday - Friday",
              time: "10:00 AM - 7:00 PM",
            ),
            SizedBox(height: 12.h),
            _BusinessHourRow(
              day: "Saturday",
              time: "10:00 AM - 5:00 PM",
            ),
            SizedBox(height: 12.h),
            _BusinessHourRow(
              day: "Sunday",
              time: "Closed",
              isClosed: true,
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emergency,
                    size: 16.w,
                    color: Colors.green,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "Emergency support available 24/7 for existing clients",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessHourRow extends StatelessWidget {
  final String day;
  final String time;
  final bool isClosed;

  const _BusinessHourRow({
    required this.day,
    required this.time,
    this.isClosed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: 13.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 13.sp,
            color: isClosed
                ? Colors.red
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            fontWeight: isClosed ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16.w,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialMediaSection extends GetView<ContactController> {
  const _SocialMediaSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Follow Us",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: controller.socialMedia
                  .map((social) => _SocialIcon(social: social))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialIcon extends GetView<ContactController> {
  final SocialMedia social;

  const _SocialIcon({required this.social});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => controller.launchUrl(social.url),
      icon: Container(
        width: 45.w,
        height: 45.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(
          social.icon,
          size: 20.w,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
