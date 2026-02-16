import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/sync/unsynced_changes_provider.dart';
import '../../application/adventure_providers.dart';
import '../../domain/adventure.dart';
import '../../domain/campaign.dart';

class DashboardController {
  static void showAdventureDialog(
    BuildContext context,
    WidgetRef ref, {
    Adventure? adventureToEdit,
  }) {
    final isEditing = adventureToEdit != null;
    final nameController = TextEditingController(text: adventureToEdit?.name);
    final descController = TextEditingController(
      text: adventureToEdit?.description,
    );
    final whatController = TextEditingController(
      text: adventureToEdit?.conceptWhat,
    );
    final conflictController = TextEditingController(
      text: adventureToEdit?.conceptConflict,
    );

    // Campaign handling
    final campaigns = ref.read(campaignListProvider);
    String? selectedCampaignId = adventureToEdit?.campaignId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Editar Aventura' : 'Criar Nova Aventura'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Aventura',
                      hintText: 'ex: O Templo Submerso',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Breve visão geral...',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  if (campaigns.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: selectedCampaignId,
                      decoration: const InputDecoration(
                        labelText: 'Campanha (Opcional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Nenhuma'),
                        ),
                        ...campaigns.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        selectedCampaignId = value;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: whatController,
                    decoration: const InputDecoration(
                      labelText: 'Qual é o local?',
                      hintText: 'ex: Um templo submerso sob o lago',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: conflictController,
                    decoration: const InputDecoration(
                      labelText: 'Qual conflito está acontecendo?',
                      hintText: 'ex: Duas facções lutam por um artefato antigo',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    if (isEditing) {
                      final updatedAdventure = adventureToEdit.copyWith(
                        name: nameController.text,
                        description: descController.text,
                        conceptWhat: whatController.text,
                        conceptConflict: conflictController.text,
                        campaignId: selectedCampaignId,
                      );
                      await ref
                          .read(adventureListProvider.notifier)
                          .update(updatedAdventure);
                      if (context.mounted) {
                        Navigator.pop(context);

                        ref.read(unsyncedChangesProvider.notifier).state = true;
                      }
                    } else {
                      final adventure = await ref
                          .read(adventureListProvider.notifier)
                          .create(
                            name: nameController.text,
                            description: descController.text,
                            conceptWhat: whatController.text,
                            conceptConflict: conflictController.text,
                            campaignId: selectedCampaignId,
                          );
                      if (context.mounted) {
                        Navigator.pop(context);

                        ref.read(unsyncedChangesProvider.notifier).state = true;

                        context.go('/adventure/${adventure.id}');
                      }
                    }
                  }
                },
                child: Text(isEditing ? 'Salvar' : 'Criar'),
              ),
            ],
          );
        },
      ),
    );
  }

  static void showCampaignDialog(
    BuildContext context,
    WidgetRef ref, {
    Campaign? campaignToEdit,
  }) {
    final isEditing = campaignToEdit != null;
    final nameController = TextEditingController(text: campaignToEdit?.name);
    final descController = TextEditingController(
      text: campaignToEdit?.description,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Campanha' : 'Criar Nova Campanha'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Campanha',
                  hintText: 'ex: Guerra do Anel',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'A história abrangente...',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                if (isEditing) {
                  final updatedCampaign = campaignToEdit.copyWith(
                    name: nameController.text,
                    description: descController.text,
                  );
                  await ref
                      .read(campaignListProvider.notifier)
                      .update(updatedCampaign);
                } else {
                  await ref
                      .read(campaignListProvider.notifier)
                      .create(
                        name: nameController.text,
                        description: descController.text,
                      );
                }

                ref.read(unsyncedChangesProvider.notifier).state = true;

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(isEditing ? 'Salvar' : 'Criar'),
          ),
        ],
      ),
    );
  }

  static void showCreateOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Nova Aventura'),
            subtitle: const Text('Criar um local de aventura independente'),
            onTap: () {
              Navigator.pop(context);
              showAdventureDialog(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Nova Campanha'),
            subtitle: const Text('Criar uma campanha para vincular aventuras'),
            onTap: () {
              Navigator.pop(context);
              showCampaignDialog(context, ref);
            },
          ),
        ],
      ),
    );
  }
}
