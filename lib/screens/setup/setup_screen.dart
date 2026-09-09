import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
 State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {

  final TextEditingController ipController = TextEditingController();

  @override
  void dispose() {
    ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xff0F172A),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Add Smart Device",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            const SizedBox(height: 30),

            const Icon(
              Icons.router_rounded,
              color: Color(0xff34B7F1),
              size: 90,
            ),

            const SizedBox(height: 30),

            Text(
              "Enter ESP32 IP Address",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: ipController,
              keyboardType: TextInputType.number,

              style: const TextStyle(color: Colors.white),

              decoration: InputDecoration(

                hintText: "192.168.1.100",

                hintStyle: const TextStyle(
                  color: Colors.white54,
                ),

                filled: true,
                fillColor: const Color(0xff1E293B),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              height: 55,

              child: ElevatedButton(

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff34B7F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),

                onPressed: () {

                  // Next step:
                  // Test connection

                },

                child: Text(
                  "Connect Device",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}