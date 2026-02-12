# Pull Request Rules

## Título

Siga o padrão Conventional Commits (igual aos commits).
Ex: `feat(adventure): add map support`

## Template de Descrição

```markdown
## O que foi feito?
- Adicionado campo de URL para mapas.
- Atualizado Hive Adapter.
- Novo widget `SmartNetworkImage` para exibir o mapa.

## Por que foi feito?
Para permitir que mestres visualizem o mapa da masmorra diretamente no editor.

## Como testar?
1. Abra uma aventura.
2. Vá na aba "Conceito".
3. Cole uma URL de imagem no campo "Mapa".
4. Salve e verifique se a imagem aparece.

## Screenshots (Opcional)
[Insira imagens aqui]
```

## Checklist Antes de Abrir

- [ ] Código compila sem erros (`flutter run`).
- [ ] Lints verificados (`flutter analyze`).
- [ ] Testes (se houver) passando.
- [ ] Auto-review realizado (evite comentários inúteis ou debug prints).
