"""Lectura y escritura transaccional de rutinas aprobadas."""

from .catalog import CatalogError


class RoutineRepository:
    def __init__(self, database, catalog):
        self.database = database
        self.catalog = catalog

    def _read(self, connection, row):
        identifier, name, description = row
        steps = connection.execute(
            "SELECT s.position,s.label,p.id,p.label,p.source,p.external_id,p.attribution "
            "FROM routine_step s JOIN pictogram p ON p.id=s.pictogram_id "
            "WHERE s.routine_id=? ORDER BY s.position",
            (identifier,),
        )
        return {
            "id": identifier, "name": name, "description": description,
            "steps": [
                {"order": position, "label": label, "pictogram": self.catalog._view(connection, picture)}
                for position, label, *picture in steps
            ],
        }

    def list(self):
        with self.database.connection() as connection:
            connection.execute("BEGIN")
            return [self._read(connection, row) for row in connection.execute(
                "SELECT id,name,description FROM routine ORDER BY name COLLATE NOCASE,id"
            )]

    def get(self, identifier):
        with self.database.connection() as connection:
            connection.execute("BEGIN")
            row = connection.execute("SELECT id,name,description FROM routine WHERE id=?", (identifier,)).fetchone()
            if not row:
                raise CatalogError(404, "No encontramos la rutina.")
            return self._read(connection, row)

    def save(self, payload, external_images, identifier=None):
        with self.catalog.write_transaction() as (connection, created):
            if connection.execute("SELECT 1 FROM profile WHERE id=1").fetchone() is None:
                raise CatalogError(409, "Configura el perfil antes de guardar una rutina.")
            if identifier is None:
                identifier = connection.execute(
                    "INSERT INTO routine(profile_id,name,description) VALUES (1,?,?)",
                    (payload.name, payload.description),
                ).lastrowid
            else:
                if not connection.execute(
                    "UPDATE routine SET name=?,description=?,updated_at=CURRENT_TIMESTAMP WHERE id=?",
                    (payload.name, payload.description, identifier),
                ).rowcount:
                    raise CatalogError(404, "No encontramos la rutina.")
                connection.execute("DELETE FROM routine_step WHERE routine_id=?", (identifier,))

            for step in payload.steps:
                if step.external_id is not None:
                    picture_id = self.catalog.arasaac_id(connection, step.external_id)
                    if picture_id is None:
                        image = external_images.get(step.external_id)
                        if image is None:
                            raise CatalogError(409, "El pictograma cambió. Reintenta la confirmación.")
                        picture_id = self.catalog.insert(
                            connection, created, step.pictogram_label, [], image, step.external_id,
                        )["id"]
                else:
                    picture_id = step.pictogram_id
                    if connection.execute("SELECT 1 FROM pictogram WHERE id=?", (picture_id,)).fetchone() is None:
                        raise CatalogError(422, "Un pictograma seleccionado ya no está disponible.")
                connection.execute(
                    "INSERT INTO routine_step(routine_id,pictogram_id,position,label) VALUES (?,?,?,?)",
                    (identifier, picture_id, step.order, step.label),
                )
            return self._read(connection, (identifier, payload.name, payload.description))

    def delete(self, identifier):
        with self.database.connection() as connection:
            if not connection.execute("DELETE FROM routine WHERE id=?", (identifier,)).rowcount:
                raise CatalogError(404, "No encontramos la rutina.")
