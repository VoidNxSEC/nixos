use crate::models::ModelInfo;
use sqlx::{sqlite::SqlitePool, Row};

/// Database connection pool
pub struct Database {
    pool: SqlitePool,
}

impl Database {
    /// Create new database connection
    pub async fn new(db_path: &str) -> anyhow::Result<Self> {
        let connection_string = format!("sqlite:{}", db_path);
        let pool = SqlitePool::connect(&connection_string).await?;

        Ok(Self { pool })
    }

    /// List all models with optional filters
    pub async fn list_models(
        &self,
        format: Option<&str>,
        backend: Option<&str>,
        limit: i64,
    ) -> anyhow::Result<Vec<ModelInfo>> {
        let mut query = String::from("SELECT * FROM models WHERE 1=1");

        if let Some(fmt) = format {
            query.push_str(&format!(" AND format = '{}'", fmt));
        }

        if let Some(backend) = backend {
            query.push_str(&format!(" AND compatible_backends LIKE '%{}%'", backend));
        }

        query.push_str(&format!(" ORDER BY name LIMIT {}", limit));

        let models = sqlx::query_as::<_, ModelInfo>(&query)
            .fetch_all(&self.pool)
            .await?;

        Ok(models)
    }

    /// Get model by ID
    pub async fn get_model_by_id(&self, id: i64) -> anyhow::Result<Option<ModelInfo>> {
        let model = sqlx::query_as::<_, ModelInfo>("SELECT * FROM models WHERE id = ?")
            .bind(id)
            .fetch_optional(&self.pool)
            .await?;

        Ok(model)
    }

    /// Get model by path
    pub async fn get_model_by_path(&self, path: &str) -> anyhow::Result<Option<ModelInfo>> {
        let model = sqlx::query_as::<_, ModelInfo>("SELECT * FROM models WHERE path = ?")
            .bind(path)
            .fetch_optional(&self.pool)
            .await?;

        Ok(model)
    }

    /// Update model last_used timestamp
    pub async fn update_last_used(&self, id: i64) -> anyhow::Result<()> {
        let now = chrono::Utc::now().to_rfc3339();

        sqlx::query(
            "UPDATE models SET last_used = ?, usage_count = usage_count + 1 WHERE id = ?",
        )
        .bind(now)
        .bind(id)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// Get models by format
    pub async fn get_models_by_format(&self, format: &str) -> anyhow::Result<Vec<ModelInfo>> {
        let models = sqlx::query_as::<_, ModelInfo>("SELECT * FROM models WHERE format = ?")
            .bind(format)
            .fetch_all(&self.pool)
            .await?;

        Ok(models)
    }

    /// Get total model count
    pub async fn count_models(&self) -> anyhow::Result<i64> {
        let row = sqlx::query("SELECT COUNT(*) as count FROM models")
            .fetch_one(&self.pool)
            .await?;

        let count: i64 = row.get("count");
        Ok(count)
    }

    /// Get total size of all models
    pub async fn total_models_size(&self) -> anyhow::Result<f64> {
        let row = sqlx::query("SELECT SUM(size_gb) as total FROM models")
            .fetch_one(&self.pool)
            .await?;

        let total: Option<f64> = row.get("total");
        Ok(total.unwrap_or(0.0))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_database_connection() {
        // This would require a test database
        // Skipping for now
    }
}
