const express = require('express');
const router = express.Router();
const { Project, Sprint, AuditLog, User } = require('../models');
const { authenticateToken } = require('../middleware/auth');
const { Op } = require('sequelize');

/**
 * @route GET /api/projects
 * @desc Get all projects with pagination
 * @access Public
 */
router.get('/', async (req, res) => {
  try {
    const { skip = 0, limit = 100 } = req.query;
    const projects = await Project.findAll({
      offset: parseInt(skip),
      limit: parseInt(limit),
      order: [['created_at', 'DESC']]
    });
    
    res.json({
      success: true,
      data: projects
    });
  } catch (error) {
    console.error('Error fetching projects:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

/**
 * @route GET /api/projects/:id
 * @desc Get a specific project by ID
 * @access Public
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const project = await Project.findByPk(id);
    
    if (!project) {
      return res.status(404).json({ 
        success: false,
        error: 'Project not found' 
      });
    }
    
    res.json({
      success: true,
      data: project
    });
  } catch (error) {
    console.error('Error fetching project:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

/**
 * @route POST /api/projects
 * @desc Create a new project
 * @access Private
 */
router.post('/', authenticateToken, async (req, res) => {
  try {
    // Generate a project key from the name if not provided
    let projectKey = req.body.key;
    if (!projectKey) {
      projectKey = req.body.name
        .toUpperCase()
        .replace(/[^A-Z0-9]/g, '_')
        .substring(0, 20);
    }
    
    const projectData = {
      ...req.body,
      key: projectKey,
      created_by: req.user.id
    };
    
    // Validate required fields
    const requiredFields = ['name', 'key', 'description', 'client_name', 'start_date', 'end_date'];
    const missingFields = requiredFields.filter(field => !projectData[field]);
    
    if (missingFields.length > 0) {
      return res.status(400).json({
        success: false,
        error: `Missing required fields: ${missingFields.join(', ')}`
      });
    }
    
    console.log('Creating project with data:', projectData);
    
    const project = await Project.create(projectData);

    // Log the project creation
    await AuditLog.create({
      user_id: req.user.id,
      user_email: req.user.email,
      user_role: req.user.role || 'unknown',
      action: 'create_project',
      action_category: 'project',
      entity_type: 'project',
      entity_id: project.id,
      entity_name: project.name,
      new_values: projectData,
      endpoint: req.originalUrl,
      http_method: req.method,
      status_code: 201,
      ip_address: req.ip,
      user_agent: req.get('User-Agent'),
      created_at: new Date()
    });
    
    res.status(201).json({
      success: true,
      data: project
    });
  } catch (error) {
    console.error('Error creating project:', error);
    console.error('Error details:', error.message);
    console.error('Error stack:', error.stack);
    
    // Log the failed attempt
    try {
      await AuditLog.create({
        user_id: req.user?.id || null,
        user_email: req.user?.email || null,
        user_role: req.user?.role || 'unknown',
        action: 'create_project_failed',
        action_category: 'project',
        entity_type: 'project',
        new_values: req.body,
        endpoint: req.originalUrl,
        http_method: req.method,
        status_code: 500,
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date()
      });
    } catch (logError) {
      console.error('Failed to log audit entry:', logError);
    }
    
    // Provide more detailed error information
    res.status(500).json({ 
      success: false,
      error: 'Internal server error',
      message: error.message,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

/**
 * @route PUT /api/projects/:id
 * @desc Update an existing project
 * @access Private
 */
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const project = await Project.findByPk(id);
    
    if (!project) {
      return res.status(404).json({ 
        success: false,
        error: 'Project not found' 
      });
    }

    // Store old values for audit logging
    const oldValues = project.toJSON();
    
    await project.update(updateData);

    // Calculate changed fields
    const changedFields = {};
    for (const key of Object.keys(updateData)) {
      if (oldValues[key] !== updateData[key]) {
        changedFields[key] = {
          old: oldValues[key],
          new: updateData[key]
        };
      }
    }

    // Log the project update
    await AuditLog.create({
      user_id: req.user.id,
      user_email: req.user.email,
      user_role: req.user.role || 'unknown',
      action: 'update_project',
      action_category: 'project',
      entity_type: 'project',
      entity_id: project.id,
      entity_name: project.name,
      old_values: oldValues,
      new_values: updateData,
      changed_fields: changedFields,
      endpoint: req.originalUrl,
      http_method: req.method,
      status_code: 200,
      ip_address: req.ip,
      user_agent: req.get('User-Agent'),
      created_at: new Date()
    });
    
    res.json({
      success: true,
      data: project
    });
  } catch (error) {
    console.error('Error updating project:', error);
    
    // Log the failed attempt
    try {
      await AuditLog.create({
        user_id: req.user?.id || null,
        user_email: req.user?.email || null,
        user_role: req.user?.role || 'unknown',
        action: 'update_project_failed',
        action_category: 'project',
        entity_type: 'project',
        entity_id: req.params.id,
        new_values: req.body,
        endpoint: req.originalUrl,
        http_method: req.method,
        status_code: 500,
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date()
      });
    } catch (logError) {
      console.error('Failed to log audit entry:', logError);
    }
    
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

/**
 * @route DELETE /api/projects/:id
 * @desc Delete a project
 * @access Private
 */
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const project = await Project.findByPk(id);
    
    if (!project) {
      return res.status(404).json({ 
        success: false,
        error: 'Project not found' 
      });
    }
    
    await project.destroy();
    
    res.status(204).send();
  } catch (error) {
    console.error('Error deleting project:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

/**
 * @route GET /api/projects/:projectId/sprints
 * @desc Get all sprints linked to a project
 * @access Public
 */
router.get('/:projectId/sprints', async (req, res) => {
  try {
    const { projectId } = req.params;
    
    // Verify project exists
    const project = await Project.findByPk(projectId);
    if (!project) {
      return res.status(404).json({ 
        success: false,
        error: 'Project not found' 
      });
    }

    const sprints = await Sprint.findAll({
      where: { project_id: projectId },
      order: [['created_at', 'DESC']]
    });

    // Calculate progress for each sprint
    const sprintsWithProgress = sprints.map(sprint => {
      const sprintData = sprint.toJSON();
      
      // Calculate progress based on completed vs planned points
      const plannedPoints = sprintData.planned_points || 0;
      const completedPoints = sprintData.completed_points || 0;
      const progress = plannedPoints > 0 ? Math.round((completedPoints / plannedPoints) * 100) : 0;
      
      return {
        ...sprintData,
        progress,
        ticket_count: 0, // TODO: Implement ticket counting when ticket system is integrated
        completed_tickets: completedPoints, // Using completed points as proxy for now
      };
    });
    
    res.json({
      success: true,
      data: sprintsWithProgress
    });
  } catch (error) {
    console.error('Error fetching project sprints:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

/**
 * @route GET /api/projects/:projectId/available-sprints
 * @desc Get sprints that can be linked to a project (not already linked)
 * @access Public
 */
router.get('/:projectId/available-sprints', async (req, res) => {
  try {
    const { projectId } = req.params;
    const { search } = req.query;
    
    // Verify project exists
    const project = await Project.findByPk(projectId);
    if (!project) {
      return res.status(404).json({ 
        success: false,
        error: 'Project not found' 
      });
    }

    const whereClause = {
      [Op.or]: [
        { project_id: null },
        { project_id: { [Op.ne]: projectId } }
      ]
    };

    // Add search filter if provided
    if (search && search.trim()) {
      whereClause.name = {
        [Op.iLike]: `%${search.trim()}%`
      };
    }

    const sprints = await Sprint.findAll({
      where: whereClause,
      order: [['created_at', 'DESC']],
      limit: 50
    });

    // Add progress calculation
    const sprintsWithProgress = sprints.map(sprint => {
      const sprintData = sprint.toJSON();
      const plannedPoints = sprintData.planned_points || 0;
      const completedPoints = sprintData.completed_points || 0;
      const progress = plannedPoints > 0 ? Math.round((completedPoints / plannedPoints) * 100) : 0;
      
      return {
        ...sprintData,
        progress,
        ticket_count: 0,
        completed_tickets: completedPoints,
      };
    });
    
    res.json({
      success: true,
      data: sprintsWithProgress
    });
  } catch (error) {
    console.error('Error fetching available sprints:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

/**
 * @route POST /api/projects/:projectId/sprints
 * @desc Link multiple existing sprints to a project
 * @access Private
 */
router.post('/:projectId/sprints', authenticateToken, async (req, res) => {
  try {
    const { projectId } = req.params;
    const { sprintIds } = req.body;

    if (!Array.isArray(sprintIds) || sprintIds.length === 0) {
      return res.status(400).json({ 
        success: false,
        error: 'Sprint IDs array is required' 
      });
    }

    // Verify project exists
    const project = await Project.findByPk(projectId);
    if (!project) {
      return res.status(404).json({ 
        success: false,
        error: 'Project not found' 
      });
    }

    // Update sprints to link them to the project
    const [updatedCount] = await Sprint.update(
      { project_id: projectId },
      {
        where: {
          id: sprintIds,
          [Op.or]: [
            { project_id: null },
            { project_id: { [Op.ne]: projectId } }
          ]
        }
      }
    );

    // TODO: Add audit logging here
    
    res.status(201).json({
      success: true,
      data: {
        message: `Successfully linked ${updatedCount} sprints to project`,
        linked_count: updatedCount
      }
    });
  } catch (error) {
    console.error('Error linking sprints to project:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

/**
 * @route POST /api/projects/:projectId/sprints/new
 * @desc Create a new sprint directly linked to a project
 * @access Private
 */
router.post('/:projectId/sprints/new', authenticateToken, async (req, res) => {
  try {
    const { projectId } = req.params;
    const { name, description, start_date, end_date } = req.body;

    if (!name || name.trim() === '') {
      return res.status(400).json({ 
        success: false,
        error: 'Sprint name is required' 
      });
    }

    // Verify project exists
    const project = await Project.findByPk(projectId);
    if (!project) {
      return res.status(404).json({ 
        success: false,
        error: 'Project not found' 
      });
    }

    const sprintData = {
      name: name.trim(),
      description: description?.trim() || null,
      start_date: start_date || null,
      end_date: end_date || null,
      project_id: projectId,
      status: 'draft',
      created_by: req.user?.id || null,
      planned_points: 0,
      completed_points: 0,
      committed_points: 0
    };

    const sprint = await Sprint.create(sprintData);

    // TODO: Add audit logging here
    
    res.status(201).json({
      success: true,
      data: {
        ...sprint.toJSON(),
        progress: 0,
        ticket_count: 0,
        completed_tickets: 0
      }
    });
  } catch (error) {
    console.error('Error creating sprint for project:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

/**
 * @route DELETE /api/projects/:projectId/sprints/:sprintId
 * @desc Unlink a sprint from a project (sets project_id to null)
 * @access Private
 */
router.delete('/:projectId/sprints/:sprintId', authenticateToken, async (req, res) => {
  try {
    const { projectId, sprintId } = req.params;

    // Verify project exists
    const project = await Project.findByPk(projectId);
    if (!project) {
      return res.status(404).json({ 
        success: false,
        error: 'Project not found' 
      });
    }

    // Find and update the sprint
    const sprint = await Sprint.findOne({
      where: { 
        id: sprintId,
        project_id: projectId 
      }
    });

    if (!sprint) {
      return res.status(404).json({ 
        success: false,
        error: 'Sprint not found in this project' 
      });
    }

    await sprint.update({ project_id: null });

    // TODO: Add audit logging here
    
    res.json({
      success: true,
      data: {
        message: 'Sprint unlinked from project successfully'
      }
    });
  } catch (error) {
    console.error('Error unlinking sprint from project:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

module.exports = router;