Estructura del Proyecto - Sprint 0


## Organización de Carpetas

- **core/**: Infraestructura global (Network, Errores).
- **shared/**: Componentes reutilizables (Design System/theme, Widgets comunes).
- **features/**: Modulos por funcionalidad. Capas de features:
  - **presentation**: UI (Pages, Widgets) y logica (ViewModel).
  - **domain**: Logica de negocio (Entities, Repositories, Usecases).
  - **data**: Implementacion de datos (Datasources,dtos, Mappers).
