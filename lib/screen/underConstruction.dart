import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UnderConstructionPage extends StatelessWidget {
  const UnderConstructionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            image: DecorationImage(fit:BoxFit.fill,image: AssetImage('assets/images/bg.png',)),
          ),
          child: const Column(
            children: [
              SizedBox(height: 50,),
              Text(
                'Page underConstruction',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontFamily: 'Kanit Bold',
                    fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 90,),
              Center(
                child: Image(image: AssetImage('assets/images/coming.png')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
