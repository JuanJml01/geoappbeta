-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.Reportes (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  email text NOT NULL,
  user_id uuid,
  latitud double precision NOT NULL,
  longitud double precision NOT NULL,
  imagen text,
  descripcion text,
  tipo text,
  estado text DEFAULT 'pendiente'::text,
  tipo_tags text,
  ubicacion_tags text,
  importancia integer DEFAULT 0,
  vistas integer DEFAULT 0,
  prioridad_comunidad boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT Reportes_pkey PRIMARY KEY (id),
  CONSTRAINT Reportes_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.logros (
  id integer NOT NULL DEFAULT nextval('logros_id_seq'::regclass),
  nombre text NOT NULL,
  descripcion text,
  icono text,
  puntos integer DEFAULT 10,
  condicion text,
  categoria text,
  nivel_requerido integer DEFAULT 1,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT logros_pkey PRIMARY KEY (id)
);
CREATE TABLE public.police (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT police_pkey PRIMARY KEY (id)
);
CREATE TABLE public.reporte_calificaciones (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  reporte_id bigint,
  user_id uuid,
  email text,
  device_id text,
  calificacion integer NOT NULL CHECK (calificacion >= 1 AND calificacion <= 5),
  comentario text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT reporte_calificaciones_pkey PRIMARY KEY (id),
  CONSTRAINT reporte_calificaciones_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT reporte_calificaciones_reporte_id_fkey FOREIGN KEY (reporte_id) REFERENCES public.Reportes(id)
);
CREATE TABLE public.temp_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  device_id text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  last_active timestamp with time zone DEFAULT now(),
  expires_at timestamp with time zone NOT NULL,
  CONSTRAINT temp_sessions_pkey PRIMARY KEY (id)
);
CREATE TABLE public.user_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  action text NOT NULL,
  details text NOT NULL,
  user_id uuid,
  timestamp timestamp with time zone NOT NULL,
  additional_data jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_logs_pkey PRIMARY KEY (id),
  CONSTRAINT user_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.usuario_logros (
  id integer NOT NULL DEFAULT nextval('usuario_logros_id_seq'::regclass),
  usuario_id uuid,
  logro_id integer,
  fecha_obtenido timestamp with time zone DEFAULT now(),
  CONSTRAINT usuario_logros_pkey PRIMARY KEY (id),
  CONSTRAINT usuario_logros_logro_id_fkey FOREIGN KEY (logro_id) REFERENCES public.logros(id),
  CONSTRAINT usuario_logros_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);
CREATE TABLE public.usuario_zonas (
  id integer NOT NULL DEFAULT nextval('usuario_zonas_id_seq'::regclass),
  usuario_id uuid,
  zona_id integer,
  es_favorita boolean DEFAULT false,
  es_vigilante boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT usuario_zonas_pkey PRIMARY KEY (id),
  CONSTRAINT usuario_zonas_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id),
  CONSTRAINT usuario_zonas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);
CREATE TABLE public.usuarios (
  id uuid NOT NULL,
  nombre text,
  ciudad text,
  bio text,
  foto text,
  nivel integer DEFAULT 1,
  puntos integer DEFAULT 0,
  es_anonimo boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT usuarios_pkey PRIMARY KEY (id),
  CONSTRAINT usuarios_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.zonas (
  id integer NOT NULL DEFAULT nextval('zonas_id_seq'::regclass),
  nombre text NOT NULL,
  descripcion text,
  latitud double precision,
  longitud double precision,
  radio_km double precision DEFAULT 1.0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT zonas_pkey PRIMARY KEY (id)
);