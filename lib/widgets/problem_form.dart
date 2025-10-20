import 'package:flutter/material.dart';

class ProblemForm extends StatefulWidget {
  const ProblemForm({super.key});

  @override
  State<ProblemForm> createState() => _ProblemFormState();
}

class _ProblemFormState extends State<ProblemForm> {
  final _formKey = GlobalKey<FormState>();
  String _descricao = '';
  String _localizacao = '';

  void _enviar() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Aqui entraria a lógica para salvar no banco ou enviar para API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Problema reportado com sucesso!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: "Descrição do Problema",
            ),
            onSaved: (value) => _descricao = value ?? '',
            validator: (value) => value!.isEmpty ? "Informe a descrição" : null,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: "Localização"),
            onSaved: (value) => _localizacao = value ?? '',
            validator: (value) =>
                value!.isEmpty ? "Informe a localização" : null,
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _enviar, child: const Text("Enviar")),
        ],
      ),
    );
  }
}
