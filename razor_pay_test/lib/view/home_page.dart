import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// intied the text editing controller variable

final TextEditingController controller = TextEditingController();

// making the payment

Future<void> createPayment() async {
  await doPayment();
}

var _razorpay = Razorpay();
late String uuid;
Future<dynamic> createOrder() async {
  final amount = int.parse(controller.text);
  final dio = Dio();
  uuid = const Uuid().v4();

  try {
    final response = await dio.post(
      'https://api.razorpay.com/v1/orders',
      options: Options(
        contentType: 'application/json',
        headers: {
          'Authorization':
              'Basic ${base64.encode(utf8.encode('rzp_test_26BIQ5TndQ5HOO:PQvS7CdE29Yf7G3OMw1d4f8O'))}',
        },
      ),
      data: jsonEncode({
        "amount": (100 * amount),
        "currency": "INR",
        "receipt": uuid,
      }),
    );
    return response.data;
  } catch (e) {
    log(e.toString());
  }
}
// there we doing the payment

Future<void> doPayment() async {
  final orderData = await createOrder();

  var options = {
    'key': 'rzp_test_26BIQ5TndQ5HOO',
    'amount': orderData['amount'],
    'name': 'LevelX',
    'order_id': '${orderData['id']}',
    'description': 'Chair',
    'timeout': 60 * 2,
    // 'prefill': {'contact': '9123456789', 'email': 'gaurav.kumar@example.com'}
  };

  _razorpay.open(options);
}

void _handlePaymentSuccess(PaymentSuccessResponse response) {
  // Do something when payment succeeds
  String secretkey = "PQvS7CdE29Yf7G3OMw1d4f8O";
  final keySecret = utf8.encode(secretkey);
  final bytes = utf8.encode('${response.orderId}|${response.paymentId}');

  final hmacSha256 = Hmac(sha256, keySecret);
  final generatedSignature = hmacSha256.convert(bytes);

  if (generatedSignature.toString() == response.signature) {
    log("Payment was successful!");
    //Handle what to do after a successful payment.

    void _handlePaymentSuccess(PaymentSuccessResponse response) {
      // Do something when payment succeeds
      final keySecret = utf8.encode(secretkey);
      final bytes = utf8.encode('${response.orderId}|${response.paymentId}');

      final hmacSha256 = Hmac(sha256, keySecret);
      final generatedSignature = hmacSha256.convert(bytes);

      if (generatedSignature.toString() == response.signature) {
        log("Payment was successful!");
        //Handle what to do after a successful payment.
        // showDialog(
        //   context: context,
        //   builder: (BuildContext context) {
        //     return AlertDialog(
        //       title: const Text("Success : payment successful"),
        //       // content: const Text("Are you sure you wish to delete this item?"),
        //       actions: <Widget>[
        //         ElevatedButton(
        //             onPressed: () {
        //               Navigator.of(context).pop();
        //               // PlaceOrderPrepaid();
        //             },
        //             child: Text("OK"))
        //         // ),
        //       ],
        //     );
        //   },
        // );
      } else {
        log("The payment was fake!");
      }
    }

    void _handlePaymentError(PaymentFailureResponse response) {
      // Do something when payment fails
    }

    void _handleExternalWallet(ExternalWalletResponse response) {
      // Do something when an external wallet is selected
    }
  } else {
    print("The payment was fake!");
  }
}

void _handlePaymentError(PaymentFailureResponse response) {
  // Do something when payment fails
}

void _handleExternalWallet(ExternalWalletResponse response) {
  // Do something when an external wallet is selected
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    super.initState();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _textFiled(),
            const SizedBox(
              height: 30,
            ),
            _clickButton()
          ],
        ),
      ),
    );
  }

  Center _clickButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          createPayment();
        },
        child: const Icon(CupertinoIcons.money_dollar),
      ),
    );
  }

  TextField _textFiled() {
    return TextField(
      controller: controller,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        hintText: "Enter Amount",
        enabledBorder: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(),
      ),
    );
  }
}
