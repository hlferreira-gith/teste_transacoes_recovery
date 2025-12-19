# E-commerce DB (MySQL 8.0) — DIO

Projeto de banco de dados para um cenário de e-commerce com:
- Clientes PF/PJ, produtos, pedidos e itens de pedido
- Colaboradores e histórico de salário (auditoria)
- Procedures para CRUD e criação transacional de pedidos
- Triggers de auditoria e validação
- Transações (manuais e via procedure)
- Backup e recovery com mysqldump

Além disso, inclui entregáveis do cenário “company”:
- Índices + consultas (departamentos/empregados/localidades)
- Views e permissões (gerente vs employee)

## Requisitos
- MySQL 8.0+
- Acesso ao terminal do MySQL (mysql client)
- Docker (opcional)

Collation recomendado: utf8mb4_0900_ai_ci.

## Estrutura do repositório
- sql/
  - 00_schema_ecommerce_core.sql
  - 05_ecommerce_procedures.sql
  - 07_triggers_ecommerce.sql
  - 08_transacoes_ecommerce.sql
  - 09_procedure_transacao_ecommerce.sql
  - indices_e_consultas_company.sql       (cenário company)
  - 06_views_permissoes_company.sql       (cenário company)
- backups/                                (arquivos .sql gerados pelo mysqldump)
- README.md

## Como executar (local)
1) Criar o schema e-commerce (core)
```sql
SOURCE sql/00_schema_ecommerce_core.sql;
