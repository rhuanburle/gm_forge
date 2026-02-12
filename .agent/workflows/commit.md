---
description: Gera uma mensagem de commit seguindo o padrão do projeto.
---

# Workflow de Commit

1. **Staging**: Adicione os arquivos que deseja commitar.
   ```bash
   git add .
   ```
   *(Ou adicione arquivos específicos)*

2. **Analysis**: Analise as mudanças.
   - Quais arquivos mudaram?
   - Qual o impacto (feat, fix, refactor)?

3. **Generation**: Gere a mensagem seguindo o padrão:
   ```text
   <type>(<scope>): <subject>

   <body>
   ```

4. **Execution**:
   ```bash
   git commit -m "mensagem gerada"
   ```
