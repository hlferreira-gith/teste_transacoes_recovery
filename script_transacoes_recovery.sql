USE ecommerce_db;
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_criar_pedido $$
CREATE PROCEDURE sp_criar_pedido(
  IN p_cliente_id BIGINT,
  IN p_itens_json JSON  -- [{"produto_id":1,"qtde":2}, ...]
)
BEGIN
  DECLARE v_pedido_id BIGINT;
  DECLARE v_insuficientes INT DEFAULT 0;
  DECLARE v_msg TEXT;
  DECLARE v_sqlstate CHAR(5);
  DECLARE v_errno INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 v_sqlstate = RETURNED_SQLSTATE, v_errno = MYSQL_ERRNO, v_msg = MESSAGE_TEXT;
    ROLLBACK;
    SELECT 'ERRO' AS status, v_errno AS mysql_errno, v_sqlstate AS sqlstate, v_msg AS mensagem;
  END;

  START TRANSACTION;

  DROP TEMPORARY TABLE IF EXISTS tmp_itens;
  CREATE TEMPORARY TABLE tmp_itens (
    produto_id BIGINT NOT NULL,
    qtde INT NOT NULL CHECK (qtde > 0)
  ) ENGINE=MEMORY;

  INSERT INTO tmp_itens (produto_id, qtde)
  SELECT jt.produto_id, jt.qtde
  FROM JSON_TABLE(p_itens_json, '$[*]' COLUMNS(
    produto_id BIGINT PATH '$.produto_id',
    qtde       INT    PATH '$.qtde'
  )) AS jt;

  SELECT id, estoque FROM produto
  WHERE id IN (SELECT produto_id FROM tmp_itens)
  FOR UPDATE;

  SELECT COUNT(*) INTO v_insuficientes
  FROM produto p
  JOIN tmp_itens t ON t.produto_id = p.id
  WHERE p.estoque < t.qtde;

  IF v_insuficientes > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estoque insuficiente para um ou mais itens';
  END IF;

  SAVEPOINT sp_itens_ok;

  INSERT INTO pedido (cliente_id, status) VALUES (p_cliente_id, 'ABERTO');
  SET v_pedido_id = LAST_INSERT_ID();

  INSERT INTO pedido_item (pedido_id, produto_id, qtde, preco_unitario)
  SELECT v_pedido_id, t.produto_id, t.qtde, p.preco
  FROM tmp_itens t
  JOIN produto p ON p.id = t.produto_id;

  UPDATE produto p
  JOIN tmp_itens t ON t.produto_id = p.id
  SET p.estoque = p.estoque - t.qtde;

  UPDATE pedido SET status='PAGO' WHERE id=v_pedido_id;

  COMMIT;

  SELECT 'OK' AS status, v_pedido_id AS pedido_id,
         (SELECT SUM(qtde*preco_unitario) FROM pedido_item WHERE pedido_id=v_pedido_id) AS total;
END $$

DELIMITER ;
