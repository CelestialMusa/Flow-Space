'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Change entity_id from INTEGER to STRING to support UUIDs
    await queryInterface.changeColumn('audit_logs', 'entity_id', {
      type: Sequelize.STRING(255),
      allowNull: true
    });
  },

  down: async (queryInterface, Sequelize) => {
    // Revert back to INTEGER (might fail if non-integer values exist)
    // We'll try to cast, but usually down migrations are for rollback
    await queryInterface.changeColumn('audit_logs', 'entity_id', {
      type: Sequelize.INTEGER,
      allowNull: true,
      // Add logic to handle casting if needed, but for now simple revert
    });
  }
};
