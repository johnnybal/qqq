import React, { useState, useEffect } from 'react';
import {
  Box,
  Tabs,
  Tab,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  Typography,
  Paper,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  CheckCircle as CheckCircleIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';

interface ContentFilter {
  id: string;
  type: string;
  pattern: string;
  action: string;
  severity: number;
  isEnabled: boolean;
  createdAt: Date;
  updatedAt: Date;
}

interface AbuseReport {
  id: string;
  reporterId: string;
  reportedContentId: string;
  contentType: string;
  reason: string;
  details: string;
  status: string;
  priority: number;
  createdAt: Date;
  resolvedAt?: Date;
  resolution?: string;
  moderatorId?: string;
}

interface UserSafetyRule {
  id: string;
  type: string;
  condition: string;
  action: string;
  isEnabled: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export const ContentModerationSystem: React.FC = () => {
  const [selectedTab, setSelectedTab] = useState(0);
  const [filters, setFilters] = useState<ContentFilter[]>([]);
  const [reports, setReports] = useState<AbuseReport[]>([]);
  const [rules, setRules] = useState<UserSafetyRule[]>([]);
  const [showAddFilter, setShowAddFilter] = useState(false);
  const [showAddRule, setShowAddRule] = useState(false);
  const [selectedReport, setSelectedReport] = useState<AbuseReport | null>(null);

  useEffect(() => {
    // Load initial data
    loadFilters();
    loadReports();
    loadRules();
  }, []);

  const loadFilters = async () => {
    // TODO: Implement API call to fetch filters
  };

  const loadReports = async () => {
    // TODO: Implement API call to fetch reports
  };

  const loadRules = async () => {
    // TODO: Implement API call to fetch rules
  };

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setSelectedTab(newValue);
  };

  const handleAddFilter = (filter: ContentFilter) => {
    setFilters([...filters, filter]);
    setShowAddFilter(false);
  };

  const handleAddRule = (rule: UserSafetyRule) => {
    setRules([...rules, rule]);
    setShowAddRule(false);
  };

  const handleUpdateReport = (report: AbuseReport) => {
    setReports(reports.map(r => r.id === report.id ? report : r));
    setSelectedReport(null);
  };

  return (
    <Box sx={{ width: '100%' }}>
      <Paper sx={{ p: 2 }}>
        <Tabs value={selectedTab} onChange={handleTabChange}>
          <Tab label="Content Filtering" />
          <Tab label="Abuse Reports" />
          <Tab label="User Safety" />
        </Tabs>

        {selectedTab === 0 && (
          <Box sx={{ mt: 2 }}>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 2 }}>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => setShowAddFilter(true)}
              >
                Add Filter
              </Button>
            </Box>
            <List>
              {filters.map(filter => (
                <ListItem key={filter.id}>
                  <ListItemText
                    primary={filter.type}
                    secondary={`Pattern: ${filter.pattern} | Action: ${filter.action}`}
                  />
                  <ListItemSecondaryAction>
                    <IconButton edge="end" aria-label="edit">
                      <EditIcon />
                    </IconButton>
                    <IconButton edge="end" aria-label="delete">
                      <DeleteIcon />
                    </IconButton>
                  </ListItemSecondaryAction>
                </ListItem>
              ))}
            </List>
          </Box>
        )}

        {selectedTab === 1 && (
          <Box sx={{ mt: 2 }}>
            <List>
              {reports.map(report => (
                <ListItem
                  key={report.id}
                  button
                  onClick={() => setSelectedReport(report)}
                >
                  <ListItemText
                    primary={report.contentType}
                    secondary={`Reason: ${report.reason} | Status: ${report.status}`}
                  />
                  <ListItemSecondaryAction>
                    {report.status === 'resolved' ? (
                      <CheckCircleIcon color="success" />
                    ) : (
                      <WarningIcon color="warning" />
                    )}
                  </ListItemSecondaryAction>
                </ListItem>
              ))}
            </List>
          </Box>
        )}

        {selectedTab === 2 && (
          <Box sx={{ mt: 2 }}>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 2 }}>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => setShowAddRule(true)}
              >
                Add Rule
              </Button>
            </Box>
            <List>
              {rules.map(rule => (
                <ListItem key={rule.id}>
                  <ListItemText
                    primary={rule.type}
                    secondary={`Condition: ${rule.condition} | Action: ${rule.action}`}
                  />
                  <ListItemSecondaryAction>
                    <IconButton edge="end" aria-label="edit">
                      <EditIcon />
                    </IconButton>
                    <IconButton edge="end" aria-label="delete">
                      <DeleteIcon />
                    </IconButton>
                  </ListItemSecondaryAction>
                </ListItem>
              ))}
            </List>
          </Box>
        )}
      </Paper>

      {/* Add Filter Dialog */}
      <Dialog open={showAddFilter} onClose={() => setShowAddFilter(false)}>
        <DialogTitle>Add Content Filter</DialogTitle>
        <DialogContent>
          {/* Add filter form fields */}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowAddFilter(false)}>Cancel</Button>
          <Button onClick={() => setShowAddFilter(false)}>Add</Button>
        </DialogActions>
      </Dialog>

      {/* Add Rule Dialog */}
      <Dialog open={showAddRule} onClose={() => setShowAddRule(false)}>
        <DialogTitle>Add Safety Rule</DialogTitle>
        <DialogContent>
          {/* Add rule form fields */}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowAddRule(false)}>Cancel</Button>
          <Button onClick={() => setShowAddRule(false)}>Add</Button>
        </DialogActions>
      </Dialog>

      {/* Report Detail Dialog */}
      <Dialog
        open={!!selectedReport}
        onClose={() => setSelectedReport(null)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Report Details</DialogTitle>
        <DialogContent>
          {selectedReport && (
            <Box>
              <Typography variant="h6">{selectedReport.contentType}</Typography>
              <Typography>Reason: {selectedReport.reason}</Typography>
              <Typography>Details: {selectedReport.details}</Typography>
              <Typography>Priority: {selectedReport.priority}</Typography>
              <Typography>
                Created: {selectedReport.createdAt.toLocaleString()}
              </Typography>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSelectedReport(null)}>Close</Button>
          <Button
            variant="contained"
            onClick={() => {
              if (selectedReport) {
                handleUpdateReport({
                  ...selectedReport,
                  status: 'resolved',
                  resolvedAt: new Date(),
                });
              }
            }}
          >
            Mark as Resolved
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}; 