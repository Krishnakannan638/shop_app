import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';


class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late GraphQLClient client;
  bool _loading = true;
  String? _error;
  dynamic orderData;

  @override
  void initState() {
    super.initState();
    _fetchOrderData();
  }

  void _fetchOrderData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final HttpLink link = HttpLink("http://localhost:3000/shop-api");  // Replace with your GraphQL endpoint

    client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: HiveStore()),
    );

    const String query = """
      query Order(\$id: ID!) {
        order(id: \$id) {
          id
          createdAt
          updatedAt
          type
          orderPlacedAt
          code
          state
          active
          customer {
            id
            firstName
            lastName
            emailAddress
          }
          shippingAddress {
            street
            city
            country
            postalCode
          }
          billingAddress {
            street
            city
            country
            postalCode
          }
          lines {
            product {
              name
            }
            quantity
            price {
              value
              currencyCode
            }
          }
          totalQuantity
          subTotal {
            value
            currencyCode
          }
          shipping {
            value
            currencyCode
          }
          total {
            value
            currencyCode
          }
        }
      }
    """;

    try {
      final QueryResult result = await client.query(
        QueryOptions(
          document: gql(query),
          variables: {"id": widget.orderId},
        ),
      );

      if (result.hasException) {
        setState(() {
          _error = result.exception.toString();
          _loading = false;
        });
        return;
      }

      setState(() {
        orderData = result.data?['order'];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "An error occurred: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : orderData == null
                  ? const Center(child: Text("Order not found"))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView(
                        children: [
                          // Order Details
                          Text("Order ID: ${orderData['id']}", style: const TextStyle(fontSize: 18)),
                          Text("Order Code: ${orderData['code']}", style: const TextStyle(fontSize: 16)),
                          Text("State: ${orderData['state']}", style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Text("Created At: ${orderData['createdAt']}", style: const TextStyle(fontSize: 14)),
                          Text("Updated At: ${orderData['updatedAt']}", style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 16),

                          // Customer Information
                          const Text("Customer Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("Name: ${orderData['customer']['firstName']} ${orderData['customer']['lastName']}"),
                          Text("Email: ${orderData['customer']['emailAddress']}"),
                          const SizedBox(height: 16),

                          // Shipping Address
                          const Text("Shipping Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("Street: ${orderData['shippingAddress']['street']}"),
                          Text("City: ${orderData['shippingAddress']['city']}"),
                          Text("Country: ${orderData['shippingAddress']['country']}"),
                          Text("Postal Code: ${orderData['shippingAddress']['postalCode']}"),
                          const SizedBox(height: 16),

                          // Billing Address
                          const Text("Billing Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("Street: ${orderData['billingAddress']['street']}"),
                          Text("City: ${orderData['billingAddress']['city']}"),
                          Text("Country: ${orderData['billingAddress']['country']}"),
                          Text("Postal Code: ${orderData['billingAddress']['postalCode']}"),
                          const SizedBox(height: 16),

                          // Order Items
                          const Text("Order Items", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: orderData['lines'].length,
                            itemBuilder: (context, index) {
                              final line = orderData['lines'][index];
                              return ListTile(
                                title: Text("${line['product']['name']}"),
                                subtitle: Text("Quantity: ${line['quantity']} - Price: ${line['price']['currencyCode']} ${line['price']['value']}"),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Total Values
                          const Text("Total Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("Total Quantity: ${orderData['totalQuantity']}"),
                          Text("Subtotal: ${orderData['subTotal']['currencyCode']} ${orderData['subTotal']['value']}"),
                          Text("Shipping: ${orderData['shipping']['currencyCode']} ${orderData['shipping']['value']}"),
                          Text("Total: ${orderData['total']['currencyCode']} ${orderData['total']['value']}"),
                        ],
                      ),
                    ),
    );
  }
}
