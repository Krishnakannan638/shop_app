import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class ProductScreen extends StatefulWidget {
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<dynamic> products = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    setState(() {
      _loading = true;
      _error = null; // Reset any previous error
    });

    final HttpLink link = HttpLink("http://localhost:3000/shop-api");

    // Initialize GraphQL Client
    final GraphQLClient qlClient = GraphQLClient(
      link: link,
      cache: GraphQLCache(
        store: HiveStore(),
      ),
    );

    try {
      final QueryResult queryResult = await qlClient.query(
        QueryOptions(
          document: gql(
            """
            query products {
              products {
                items {
                  id
                  name
                  slug
                  description
                  enabled
                  featuredAsset {
                    source
                  }
                  assets {
                    source
                  }
                }
              }
            }
            """,
          ),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (queryResult.hasException) {
        setState(() {
          _error = queryResult.exception.toString();
          _loading = false;
        });
        return;
      }

      setState(() {
        products = queryResult.data?['products']['items'] ?? [];
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
        title: const Text("Product List",
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
                        onPressed: fetchData,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : products.isEmpty
                  ? Center(
                      child: ElevatedButton(
                        onPressed: fetchData,
                        child: const Text("Fetch Products"),
                      ),
                    )
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
                                  if (product['featuredAsset']?['source'] !=
                                      null)
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
                                    product['description'],
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  // Variants
                                  // if (product['variants'] != null &&
                                  //     product['variants'].isNotEmpty)
                                  //   Column(
                                  //     crossAxisAlignment:
                                  //         CrossAxisAlignment.start,
                                  //     children: [
                                  //       const Text(
                                  //         "Variants:",
                                  //         style: TextStyle(
                                  //             fontSize: 16,
                                  //             fontWeight: FontWeight.bold),
                                  //       ),
                                  //       ...product['variants']
                                  //           .map<Widget>((variant) {
                                  //         // Safely access the price
                                  //         return Text(
                                  //             "- \$${variant['price'] ?? 'N/A'}");
                                  //       }).toList(),
                                  //     ],
                                  //   )
                                  // else
                                  //   Text("No variants available"),

                                  const SizedBox(height: 8),
                                  // Assets
                                  if (product['assets'] != null &&
                                      product['assets'].isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Additional Assets:",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        ...product['assets']
                                            .map<Widget>((asset) {
                                          return Image.network(
                                            asset['source'],
                                            height: 100,
                                            fit: BoxFit.cover,
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  // Product Slug (for URL or further info)
                                  Text(
                                    "Slug: ${product['slug']}",
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
