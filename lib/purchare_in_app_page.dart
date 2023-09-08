import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_cvmaker/style.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cvmaker/utils/constants.dart';

const List<String> productId = <String>[
    Constants.KEY_1_COIN,
    Constants.KEY_2_COIN,
    Constants.KEY_3_COIN,
    Constants.KEY_4_COIN,
    Constants.KEY_5_COIN,
    Constants.KEY_6_COIN,
    Constants.KEY_7_COIN,
];
class PurchareInAppPage extends StatefulWidget {
  const PurchareInAppPage({super.key});

  @override
  State<PurchareInAppPage> createState() => _PurchareInAppPageState();
}

class _PurchareInAppPageState extends State<PurchareInAppPage> {
  // Instantiates inAppPurchase
  final InAppPurchase _iap = InAppPurchase.instance;

  // checks if the API is available on this device
  bool _isAvailable = false;

  // keeps a list of products queried from Playstore or app store
  List<ProductDetails> _products = [];

  // subscription that listens to a stream of updates to purchase details
  late StreamSubscription _subscription;

  late ProductDetails productDetails;

  Future<void> _initialize() async {
    // Check availability of InApp Purchases
    _isAvailable = await _iap.isAvailable();

    // perform our async calls only when in-app purchase is available
    if (_isAvailable) {
      await _getUserProducts();

      _subscription = _iap.purchaseStream.listen((purchaseList) {
        _listenToPurchase(purchaseList, context);
      }, onDone: () {
        _subscription.cancel();
      }, onError: (error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Lỗi")));
      });
    }
  }

  // Method to retrieve product list
  Future<void> _getUserProducts() async {
    Set<String> ids = {
      Constants.KEY_1_COIN,
      Constants.KEY_2_COIN,
      Constants.KEY_3_COIN,
      Constants.KEY_4_COIN,
      Constants.KEY_5_COIN,
      Constants.KEY_6_COIN,
      Constants.KEY_7_COIN,
    };
    ProductDetailsResponse response = await _iap.queryProductDetails(ids);

    setState(() {
      _products = response.productDetails;
    });
  }

// listen Purchase
  _listenToPurchase(
      List<PurchaseDetails> purchaseDetailsList, BuildContext context) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Dang Chờ")));
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Lỗi")));
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        if (productDetails != null){
          if (productDetails.description.endsWith(" coin")){
            var coinPurchased = int.tryParse(productDetails.description.substring(0, productDetails.description.length - 5));
            await saveCoinAndGoBack(coinPurchased ?? 0);
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã mua thành công")));
      }
    });
  }

  // Method to purchase a product
  Future<void> _buyProduct(ProductDetails prod) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
    await _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: false);

    setState(() {
      productDetails = prod;
    });

  }

  Future<void> saveCoinAndGoBack(int coin) async {
    final sharedPrefService = await SharedPreferences.getInstance();

    var currentCoin = sharedPrefService.getInt("coin") ?? 30;
    var newCoin = currentCoin + coin;
    await sharedPrefService.setInt("coin", newCoin);

    Navigator.pop(context);
  }

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  @override
  void dispose() {
    // cancelling the subscription
    _subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cửa hàng'),
        centerTitle: true,
      ),
      body: ListView.builder(
          itemCount: _products.length,
          itemBuilder: (BuildContext context, int index) {
            var item = _products[index];
            return Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFF05A22),
                  style: BorderStyle.solid,
                  width: 1.0,
                ),
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_coin.svg',
                    width: 40,
                    height: 40,
                    colorFilter:
                    const ColorFilter.mode(Colors.yellow, BlendMode.srcIn),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.description}',
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          '${item.price}',
                        )
                      ],
                    ),
                  ),
                  ElevatedButton(
                    child: const Text('Mua'),
                    onPressed: () => _buyProduct(item),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                ],
              ),
            );
          }),
    );
  }
}