set extra_float_digits =0;
SELECT set_smlar_limit(0.6);

SELECT 
	t,
	ARRAY(
		SELECT 
			('01:01:01:01:01:' || (v % 100))::macaddr
		FROM
			generate_series(1, t) as v
	) AS v
	INTO test_macaddr
FROM
	generate_series(1, 200) as t;


SELECT	t, smlar(v, '{01:01:01:01:01:10,01:01:01:01:01:9,01:01:01:01:01:8,01:01:01:01:01:7,01:01:01:01:01:6,01:01:01:01:01:5,01:01:01:01:01:4,01:01:01:01:01:3,01:01:01:01:01:2,01:01:01:01:01:1}') AS s FROM test_macaddr WHERE v % '{01:01:01:01:01:10,01:01:01:01:01:9,01:01:01:01:01:8,01:01:01:01:01:7,01:01:01:01:01:6,01:01:01:01:01:5,01:01:01:01:01:4,01:01:01:01:01:3,01:01:01:01:01:2,01:01:01:01:01:1}' ORDER BY s DESC, t;
SELECT	t, smlar(v, '{01:01:01:01:01:50,01:01:01:01:01:49,01:01:01:01:01:8,01:01:01:01:01:7,01:01:01:01:01:6,01:01:01:01:01:5,01:01:01:01:01:4,01:01:01:01:01:33,01:01:01:01:01:2,01:01:01:01:01:1}') AS s FROM test_macaddr WHERE v % '{01:01:01:01:01:50,01:01:01:01:01:49,01:01:01:01:01:8,01:01:01:01:01:7,01:01:01:01:01:6,01:01:01:01:01:5,01:01:01:01:01:4,01:01:01:01:01:33,01:01:01:01:01:2,01:01:01:01:01:1}' ORDER BY s DESC, t;

CREATE INDEX idx_test_macaddr ON test_macaddr USING gist (v _macaddr_sml_ops);

SET enable_seqscan=off;

SELECT	t, smlar(v, '{01:01:01:01:01:10,01:01:01:01:01:9,01:01:01:01:01:8,01:01:01:01:01:7,01:01:01:01:01:6,01:01:01:01:01:5,01:01:01:01:01:4,01:01:01:01:01:3,01:01:01:01:01:2,01:01:01:01:01:1}') AS s FROM test_macaddr WHERE v % '{01:01:01:01:01:10,01:01:01:01:01:9,01:01:01:01:01:8,01:01:01:01:01:7,01:01:01:01:01:6,01:01:01:01:01:5,01:01:01:01:01:4,01:01:01:01:01:3,01:01:01:01:01:2,01:01:01:01:01:1}' ORDER BY s DESC, t;
SELECT	t, smlar(v, '{01:01:01:01:01:50,01:01:01:01:01:49,01:01:01:01:01:8,01:01:01:01:01:7,01:01:01:01:01:6,01:01:01:01:01:5,01:01:01:01:01:4,01:01:01:01:01:33,01:01:01:01:01:2,01:01:01:01:01:1}') AS s FROM test_macaddr WHERE v % '{01:01:01:01:01:50,01:01:01:01:01:49,01:01:01:01:01:8,01:01:01:01:01:7,01:01:01:01:01:6,01:01:01:01:01:5,01:01:01:01:01:4,01:01:01:01:01:33,01:01:01:01:01:2,01:01:01:01:01:1}' ORDER BY s DESC, t;

DROP INDEX idx_test_macaddr;
CREATE INDEX idx_test_macaddr ON test_macaddr USING gin (v _macaddr_sml_ops);

SELECT	t, smlar(v, '{01:01:01:01:01:10,01:01:01:01:01:9,01:01:01:01:01:8,01:01:01:01:01:7,01:01:01:01:01:6,01:01:01:01:01:5,01:01:01:01:01:4,01:01:01:01:01:3,01:01:01:01:01:2,01:01:01:01:01:1}') AS s FROM test_macaddr WHERE v % '{01:01:01:01:01:10,01:01:01:01:01:9,01:01:01:01:01:8,01:01:01:01:01:7,01:01:01:01:01:6,01:01:01:01:01:5,01:01:01:01:01:4,01:01:01:01:01:3,01:01:01:01:01:2,01:01:01:01:01:1}' ORDER BY s DESC, t;
SELECT	t, smlar(v, '{01:01:01:01:01:50,01:01:01:01:01:49,01:01:01:01:01:8,01:01:01:01:01:7,01:01:01:01:01:6,01:01:01:01:01:5,01:01:01:01:01:4,01:01:01:01:01:33,01:01:01:01:01:2,01:01:01:01:01:1}') AS s FROM test_macaddr WHERE v % '{01:01:01:01:01:50,01:01:01:01:01:49,01:01:01:01:01:8,01:01:01:01:01:7,01:01:01:01:01:6,01:01:01:01:01:5,01:01:01:01:01:4,01:01:01:01:01:33,01:01:01:01:01:2,01:01:01:01:01:1}' ORDER BY s DESC, t;

SET enable_seqscan=on;

