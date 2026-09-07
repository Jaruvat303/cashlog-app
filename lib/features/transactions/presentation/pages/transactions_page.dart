import 'package:flutter/material.dart';

import 'transaction_form_page.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: const Center(child: Text('Transactions — coming soon')),
      // T7 builds the real feed; this FAB is T6's only reachable entry
      // point until then.
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionFormPage())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
