-- Este script añade las columnas faltantes a la tabla Reportes existente
-- y configura las políticas de seguridad necesarias

-- 1. Añadir las columnas faltantes si no existen
DO $$
BEGIN
    -- Añadir tipo_tags si no existe
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Reportes' 
        AND column_name = 'tipo_tags'
    ) THEN
        ALTER TABLE public."Reportes" ADD COLUMN tipo_tags TEXT;
        RAISE NOTICE 'Columna tipo_tags añadida';
    END IF;
    
    -- Añadir ubicacion_tags si no existe
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'Reportes' 
        AND column_name = 'ubicacion_tags'
    ) THEN
        ALTER TABLE public."Reportes" ADD COLUMN ubicacion_tags TEXT;
        RAISE NOTICE 'Columna ubicacion_tags añadida';
    END IF;

    -- Hacer user_id nullable (para permitir usuarios anónimos)
    ALTER TABLE public."Reportes" ALTER COLUMN user_id DROP NOT NULL;
    
    -- Actualizar datos existentes para que tipo_tags tome el valor de tipo
    UPDATE public."Reportes" 
    SET tipo_tags = tipo 
    WHERE tipo_tags IS NULL AND tipo IS NOT NULL;
    
    -- Establecer ubicacion_tags predeterminado para registros existentes
    UPDATE public."Reportes"
    SET ubicacion_tags = 'otro'
    WHERE ubicacion_tags IS NULL;
END $$;

-- 2. Configurar políticas de seguridad para la tabla Reportes
ALTER TABLE public."Reportes" ENABLE ROW LEVEL SECURITY;

-- Permitir acceso público para SELECT
DROP POLICY IF EXISTS "Permitir acceso público a reportes" ON public."Reportes";
CREATE POLICY "Permitir acceso público a reportes" 
ON public."Reportes" FOR SELECT 
TO authenticated, anon
USING (true);

-- Permitir inserción para usuarios autenticados
DROP POLICY IF EXISTS "Permitir insertar reportes a usuarios autenticados" ON public."Reportes";
CREATE POLICY "Permitir insertar reportes a usuarios autenticados" 
ON public."Reportes" FOR INSERT 
TO authenticated
WITH CHECK (true);

-- Permitir inserción para usuarios anónimos (con email que contenga 'anonymous')
DROP POLICY IF EXISTS "Permitir insertar reportes anónimos" ON public."Reportes";
CREATE POLICY "Permitir insertar reportes anónimos" 
ON public."Reportes" FOR INSERT 
TO anon
WITH CHECK (email LIKE '%anonymous%');

-- Permitir actualización sólo de propios reportes
DROP POLICY IF EXISTS "Permitir actualizar propios reportes" ON public."Reportes";
CREATE POLICY "Permitir actualizar propios reportes" 
ON public."Reportes" FOR UPDATE 
TO authenticated
USING (auth.uid() = user_id OR user_id IS NULL)
WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- 3. Añadir índices para mejorar consultas
CREATE INDEX IF NOT EXISTS idx_reportes_geo 
ON public."Reportes" (latitud, longitud);

CREATE INDEX IF NOT EXISTS idx_reportes_email 
ON public."Reportes" (email);

-- NOTA: Para configurar las políticas de storage.objects, usa la interfaz web de Supabase
-- como se describió en el archivo anterior. 