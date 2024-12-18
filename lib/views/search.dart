import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<dynamic> items = [];
  List<dynamic> facets = [];
  List<dynamic> collections = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    performSearch();
  }

  void performSearch({String term = ""}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Initialize the GraphQL HTTP link
    final HttpLink link = HttpLink("http://localhost:3000/shop-api");

    // Initialize GraphQL Client
    final GraphQLClient client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: HiveStore()),
    );

    // Define the search query
    const String query = """
      query Search(\$input: SearchInput!) {
        search(input: \$input) {
          items {
            productId
            productName
          }
          totalItems
          facetValues {
            count
           
          }
        }
      }
    """;

    try {
      // Perform the GraphQL query
      final QueryResult result = await client.query(
        QueryOptions(
          document: gql(query),
          variables: {
            "input": {
              "term": term, // Search term
              "groupByProduct": true,
              "take": 20, // Number of items to fetch
            },
          },
        ),
      );

      // Handle query exceptions
      if (result.hasException) {
        setState(() {
          _error = result.exception.toString();
          _loading = false;
        });
        return;
      }

      // Parse the data and update the state
      setState(() {
        items = result.data?['search']['items'] ?? [];
        facets = result.data?['search']['facetValues'] ?? [];
        collections = result.data?['search']['collections'] ?? [];
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
      appBar: AppBar(title: const Text("Search Results",
        style: TextStyle(
          fontWeight: FontWeight.bold
        ),)),
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
                        onPressed: performSearch,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : items.isEmpty
                  ? const Center(child: Text("No results found."))
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Name
                                  Text(
                                    item['productName'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: performSearch,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
