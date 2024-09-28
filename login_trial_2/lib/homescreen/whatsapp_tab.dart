import 'package:flutter/material.dart';
import 'package:login_trial_2/homescreen/appdataprovider.dart';
import 'package:provider/provider.dart';
// import 'app_data_provider.dart'; // import the provider file

class WhatsAppTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppDataProvider>(context);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // Simulate refreshing WhatsApp data
            appData.refreshWhatsAppMessages();
          },
          child: Text("Refresh WhatsApp"),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: appData.whatsappMessages.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(appData.whatsappMessages[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
