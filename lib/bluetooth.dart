// Asynchronously paired for Bluetooth and Connection
import 'dart:async';
import 'dart:convert';

// PlatformException
import 'package:flutter/services.dart';

// Bluetooth
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

// For UI
import 'package:flutter/material.dart';
import 'CardforSlider.dart';
import 'constant.dart';

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;                      // Bluetooth Connection: Unknown
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>(); // Global key = new for SnackBar Later
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;          // Control and retrieve Bluetooth Data
  BluetoothConnection connection;                                               // Track

  bool isDisconnecting = false;       // Connection Signal (Disconnect)
  int brightness=50;                  // Brightness starts with 50
  int colourtemperature=127;          // Colour Temperature starts with 127
  bool isSwitched = false;            // Switch button for ON an OFF, starts with OFF
  bool _connected = false;            // Connection Signal(Connected), starts with Disconnected
  bool _isButtonUnavailable = false;  // Connection Switch


  bool get isConnected => connection != null && connection.isConnected; // Track Bluetooth connection

  List<BluetoothDevice> _devicesList = []; // List of Bluetooth Connection
  BluetoothDevice _device;                 // Connected Device

  @override
  void initState() {
    super.initState();

    // Current State
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
    // App first start up phone, require phone to get permission to enable
    enableBluetooth();

    // When Bluetooth Switch Status change to ON, time to paired the devices.
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_OFF) {
          _isButtonUnavailable = true;
        }
        getPairedDevices();
      });
    });
  }

  @override
  void dispose() {
    // Avoid Disconnection
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }
    super.dispose();
  }

  // Request Bluetooth Permission
  Future<void> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // Turn it on if the Bluetooth is OFF
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  // Get list of Bluetooth Devices Paired
  // Future waits for asynchronous operation to finish
  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    // Unable to set state if mounted is not true
    if (!mounted) {
      return;
    }
    // Store Devices
    setState(() {
      _devicesList = devices;
    });
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Color(0xFFFFE5B4),
          actions: <Widget>[
            TextButton.icon(
              icon: Icon(
                Icons.refresh,
                color: Colors.black,
              ),
              label: Text(
                "Refresh",
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  color: Colors.black,
                ),
              ),
              onPressed: () async {
                await getPairedDevices().then((_) {
                  show('Device list refreshed');
                });
              },
            ),
          ],
        ),
        body: Container(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              SizedBox(
                height: 5.0,
              ),
              Image(
                image:AssetImage(
                  'images/lightbulb.jpg',
                ),
                width: 80.0,
              ),
              Text(
                'Welcome',
                style: welcomeTextStyle,
              ),
              Text(
                  'Hello There!',
                  style: helloTextStyle
              ),
              SizedBox(
                height: 5.0,
                width: 200.0,
                child: Divider(
                  color: Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Enable Bluetooth',
                        style: rowsTextStyle,
                      ),
                    ),
                    Switch(
                      value: _bluetoothState.isEnabled,
                      onChanged: (bool value) {
                        future() async {
                          if (value) {
                            // Enable Bluetooth
                            await FlutterBluetoothSerial.instance
                                .requestEnable();
                          } else {
                            // Disable Bluetooth
                            await FlutterBluetoothSerial.instance
                                .requestDisable();
                          }
                          // In order to update the devices list
                          await getPairedDevices();
                          _isButtonUnavailable = false;
                          // Disconnect from any device before
                          // turning off Bluetooth
                          if (_connected) {
                            _disconnect();
                          }
                        }
                        future().then((_) {
                          setState(() {});
                        });
                      },
                      activeColor: activeSwitchColour,
                      inactiveTrackColor: inactiveSwitchColour,
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Device:',
                      style: rowsTextStyle,
                    ),
                    DropdownButton(
                      items: _getDeviceItems(),
                      onChanged: (value) =>
                          setState(() => _device = value),
                      value: _devicesList.isNotEmpty ? _device : null,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFFFFE5B4),
                        onPrimary: Colors.black,
                      ),
                      onPressed: _isButtonUnavailable
                          ? null
                          : _connected ? _disconnect : _connect,
                      child:
                      Text(_connected ? 'Disconnect' : 'Connect',
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Expanded(
                      child:
                      Text("LED",
                        style: rowsTextStyle,
                      ),
                    ),
                    Switch(value:isSwitched,onChanged: (bool value) {
                      if (value) {
                        if (_connected) {
                          setState(() {
                            isSwitched = value;
                            _sendOnMessageToBluetooth();
                            print(isSwitched);
                          });
                        }
                      }
                      else {
                        if (_connected) {
                          setState(() {
                            isSwitched = value;
                            _sendOffMessageToBluetooth();
                            print(isSwitched);
                          });
                        }
                      }
                    },
                      activeColor: activeSwitchColour,
                      inactiveTrackColor: inactiveSwitchColour,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFFFFE5B4),
                        onPrimary: Colors.black,
                      ),
                      onPressed: _connected
                          ? _sendWARMMessageToBluetooth
                          : null,
                      child: Text("WARM",
                        style: TextStyle(
                            fontFamily: 'Quicksand'
                        ),
                      ),
                    ),
                    SizedBox(width: 15),  // Gap
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFFFFE5B4),
                        onPrimary: Colors.black,
                      ),
                      onPressed: _connected
                          ? _sendCOOLMessageToBluetooth
                          : null,
                      child: Text("COOL",
                        style: TextStyle(
                            fontFamily: 'Quicksand'
                        ),
                      ),
                    ),
                    SizedBox(width: 15),  // Gap
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFFFFE5B4),
                        onPrimary: Colors.black,
                      ),
                      onPressed: _connected
                          ? _sendCustomMessageToBluetooth
                          : null,
                      child: Text("Custom",
                        style: TextStyle(
                            fontFamily: 'Quicksand'
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: CardforSlider(
                      colour: activeCardColour, //colour for card
                      cardChild: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            height: 5.0,
                          ),
                          Text(
                              'BRIGHTNESS',
                              style: labelTextStyle
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                brightness.toString(),
                                style: labelTextStyle,
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
                              overlayShape: RoundSliderOverlayShape(overlayRadius: 20.0),
                            ),
                            child: Slider(
                              value: brightness.toDouble(),
                              min: 0.0,
                              max: 100.0,
                              activeColor: activeSliderColour,
                              inactiveColor: inactiveSliderColour,
                              onChanged: (double value) {
                                if (_connected) {
                                  setState(() {
                                    brightness = value.round();
                                    _sendBrightnessToBluetooth();
                                  },
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(child: CardforSlider(
                    colour: activeCardColour,
                    cardChild:
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          height: 5.0,
                        ),
                        Text('COLOUR TEMPERATURE',
                          style: labelTextStyle,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                                colourtemperature.toString(),
                                style: labelTextStyle
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
                            overlayShape: RoundSliderOverlayShape(overlayRadius: 20.0),
                          ),
                          child: Slider(
                            value: colourtemperature.toDouble(),
                            min: 0,
                            max: 255,
                            activeColor: activeSliderColour,
                            inactiveColor: inactiveSliderColour,
                            onChanged: (double value) {
                              if (_connected) {
                                setState(() {
                                  colourtemperature = value.round();
                                  _sendCTToBluetooth();
                                },
                                );
                              }
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Warm',
                                style: warmTextStyle
                            ),
                            Text('Cool',
                                style: coolTextStyle
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }

  // Create the List of devices to be shown in Dropdown Menu
  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }

  // Method to connect to bluetooth
  void _connect() async {
    setState(() {
      _isButtonUnavailable = true;
    });
    if (_device == null) {
      show('No device selected');
    } else {
      if (!isConnected) {
        await BluetoothConnection.toAddress(_device.address)
            .then((_connection) {
          print('Connected to the device');
          connection = _connection;
          setState(() {
            _connected = true;
          });

          connection.input.listen(null).onDone(() {
            if (isDisconnecting) {
              print('Disconnecting locally!');
            } else {
              print('Disconnected remotely!');
            }
            if (this.mounted) {
              setState(() {});
            }
          });
        }).catchError((error) {
          print('Cannot connect, exception occurred');
          print(error);
        });
        show('Device connected');
        setState(() => _isButtonUnavailable = false);
      }
    }
  }

  // Disconnect Bluetooth
  void _disconnect() async {
    setState(() {
      _isButtonUnavailable = true;
    });

    await connection.close();
    show('Device disconnected');
    if (!connection.isConnected) {
      setState(() {
        _connected = false;
        _isButtonUnavailable = false;
      });
    }
  }

  // LED Switch ON & SnackBar
  void _sendOnMessageToBluetooth() async {
    connection.output.add(utf8.encode("LED:" + "1" + "\r\n"));
    await connection.output.allSent;
    show('LEDs Turned On');
    setState(() {
      isSwitched=true;
    });
  }

  // LED Switch OFF & SnackBar
  void _sendOffMessageToBluetooth() async {
    connection.output.add(utf8.encode("LED:" + "0" + "\r\n"));
    await connection.output.allSent;
    show('LEDs Turned Off');
    setState(() {
      isSwitched=false;
    });
  }

  // WARM Button & SnackBar
  void _sendWARMMessageToBluetooth() async {
    connection.output.add(utf8.encode("Auto:" + "3000" + "\r\n"));
    await connection.output.allSent;
    show('WARM Turned On');
  }

  // COOL Button & SnackBar
  void _sendCOOLMessageToBluetooth() async {
    connection.output.add(utf8.encode("Auto:" + "5700" + "\r\n"));
    await connection.output.allSent;
    show('COOL Turned On');
  }

  // CUSTOM Button & SnackBar
  void _sendCustomMessageToBluetooth() async {
    connection.output.add(utf8.encode("Auto:" + "1" + "\r\n"));
    await connection.output.allSent;
    show('Customisation Turned On');
  }

  // Brightness Slider & SnackBar
  void _sendBrightnessToBluetooth() async {
    connection.output.add(utf8.encode("Brightness:" + brightness.toString()+ "\r\n"));
    await connection.output.allSent;
  }

  // Colour Temperature Slider & SnackBar
  void _sendCTToBluetooth() async {
    connection.output.add(utf8.encode("Colour Temperature:" + colourtemperature.toString() + "\r\n"));
    await connection.output.allSent;
  }

  // SnackBar
  Future show(
      String message, {
        Duration duration: const Duration(seconds: 3),
      }) async {
    await new Future.delayed(new Duration(milliseconds: 100));

    // ScaffoldMessenger.of(context).showSnackBar(
    _scaffoldKey.currentState.showSnackBar(
      new SnackBar(
        content: new Text(
          message,
        ),
        duration: duration,
      ),
    );
  }
}