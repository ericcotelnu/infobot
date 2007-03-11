CREATE TABLE seen (
    nick VARCHAR(20) NOT NULL,
    "time" numeric NOT NULL,
    channel VARCHAR(20) NOT NULL,
    host VARCHAR(80) NOT NULL,
    message text NOT NULL,
    hehcount numeric DEFAULT 0 NOT NULL,
    messagecount numeric DEFAULT 0 NOT NULL
) WITHOUT OIDS;

REVOKE ALL ON TABLE seen FROM PUBLIC;

ALTER TABLE ONLY seen
    ADD CONSTRAINT seen_pkey PRIMARY KEY (nick, channel);
