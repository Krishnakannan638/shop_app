import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';


class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  int _page = 1;
  List<dynamic> products = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final HttpLink link = HttpLink("http://localhost:3000/shop-api");

    final GraphQLClient client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: HiveStore()),
    );

    const String query = """
      query Products(\$options: ProductListOptions) {
        products(options: \$options) {
          items {
            id
            name
            description
            
            featuredAsset {
              source
            }
          }
          totalItems
        }
      }
    """;

    try {
      final QueryResult result = await client.query(
        QueryOptions(
          document: gql(query),
          variables: {
            "options": {
              "take": 10,
              "skip": (_page - 1) * 10,
            },
          },
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
        products = result.data?['products']['items'] ?? [];
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
        title: const Text('Products',
        style: TextStyle(
          fontWeight: FontWeight.bold
        ),),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchProducts,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : products.isEmpty
                  ? const Center(child: Text("No products found"))
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Featured Image
                                  if (product['featuredAsset']?['source'] != null)
                                    Image.network(
                                      product['featuredAsset']['source'],
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  const SizedBox(height: 8),
                                  // Product Name
                                  Text(
                                    product['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Description
                                  Text(
                                    product['description'] ?? '',
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  // Price
                                  if (product['price'] != null)
                                    Text(
                                      "Price: ${product['price']['currencyCode']} ${product['price']['value']}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[200],
        onPressed: () {
          setState(() {
            _page++;
          });
          _fetchProducts();
        },
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
