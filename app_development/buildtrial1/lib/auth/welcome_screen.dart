import 'package:flutter/material.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Positioned(
          //   child: Image.asset('asset.logowobg.png'),
          // ),
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/login.png'),
                fit: BoxFit.cover,
                // Ensures the image covers the entire screen
              ),
            ),
          ),
          // Top-left "Welcome Back"
          Positioned(
            left: 40,
            top: 135,
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: "Welcome\n",
                    style: TextStyle(
                        color: Color.fromARGB(213, 209, 236, 255),
                        fontSize: 50,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(blurRadius: 3)]),
                  ),
                  TextSpan(
                    text: "\t\t\t\t\t\tto\n",
                    style: TextStyle(
                        color: Color.fromARGB(213, 209, 236, 255),
                        fontSize: 50,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(blurRadius: 3)]),
                  ),
                ],
              ),
            ),
          ),
          // Bottom-right "Welcome Back"
          Positioned(
            left: 160,
            bottom: 100,
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: "Uni-Dash\n",
                    style: TextStyle(
                        color: Color.fromARGB(213, 209, 236, 255),
                        fontSize: 50,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(blurRadius: 3)]),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 65,
            top: 350,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, "/login");
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color.fromARGB(99, 0, 0, 0), // Background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // Rounded corners
                  ),
                  elevation: 3),
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "Login",
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 3)]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 420,
            right: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, "/register");
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color.fromARGB(99, 0, 0, 0), // Background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // Rounded corners
                  ),
                  elevation: 3),
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "Register",
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 3)]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Center logo
          Positioned(
            top: 330,
            child: Container(
              height: 175,
              width: 175,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/logowobg.png"),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
