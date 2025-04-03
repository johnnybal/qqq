import React, { useEffect, useState } from 'react';
import {
  Container,
  Paper,
  Typography,
  Box,
  TextField,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  IconButton,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Chip,
} from '@mui/material';
import { db } from '../config/firebase';
import { collection, query, where, getDocs, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import BlockIcon from '@mui/icons-material/Block';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';

interface User {
  id: string;
  email: string;
  displayName: string;
  schoolId: string;
  schoolName: string;
  isPremium: boolean;
  isBlocked: boolean;
  createdAt: Date;
  lastActive: Date;
}

const UserManagement: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [openDialog, setOpenDialog] = useState(false);
  const [dialogType, setDialogType] = useState<'edit' | 'delete' | 'block' | 'unblock'>('edit');

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      const usersRef = collection(db, 'users');
      const usersSnapshot = await getDocs(usersRef);
      
      const usersData: User[] = [];
      
      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        
        // Get school name
        let schoolName = 'Unknown School';
        if (userData.schoolId) {
          const schoolRef = doc(db, 'schools', userData.schoolId);
          const schoolDoc = await getDocs(collection(db, 'schools'));
          const school = schoolDoc.docs.find(doc => doc.id === userData.schoolId);
          if (school) {
            schoolName = school.data().name || 'Unknown School';
          }
        }
        
        usersData.push({
          id: userDoc.id,
          email: userData.email || '',
          displayName: userData.displayName || '',
          schoolId: userData.schoolId || '',
          schoolName,
          isPremium: userData.isPremium || false,
          isBlocked: userData.isBlocked || false,
          createdAt: userData.createdAt?.toDate() || new Date(),
          lastActive: userData.lastActive?.toDate() || new Date(),
        });
      }
      
      // Sort by last active (descending)
      usersData.sort((a, b) => b.lastActive.getTime() - a.lastActive.getTime());
      
      setUsers(usersData);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching users:', error);
      setLoading(false);
    }
  };

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(event.target.value);
    setPage(0);
  };

  const handleOpenDialog = (user: User, type: 'edit' | 'delete' | 'block' | 'unblock') => {
    setSelectedUser(user);
    setDialogType(type);
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setSelectedUser(null);
  };

  const handleUpdateUser = async () => {
    if (!selectedUser) return;
    
    try {
      const userRef = doc(db, 'users', selectedUser.id);
      
      if (dialogType === 'delete') {
        await deleteDoc(userRef);
      } else {
        const updateData: any = {};
        
        if (dialogType === 'block') {
          updateData.isBlocked = true;
        } else if (dialogType === 'unblock') {
          updateData.isBlocked = false;
        }
        
        await updateDoc(userRef, updateData);
      }
      
      // Refresh users
      fetchUsers();
      handleCloseDialog();
    } catch (error) {
      console.error('Error updating user:', error);
    }
  };

  const filteredUsers = users.filter(user => 
    user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.displayName.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.schoolName.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading) {
    return <Typography>Loading users...</Typography>;
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Paper sx={{ p: 2 }}>
        <Typography variant="h5" gutterBottom>
          User Management
        </Typography>
        
        <Box sx={{ mb: 2 }}>
          <TextField
            fullWidth
            label="Search Users"
            variant="outlined"
            value={searchTerm}
            onChange={handleSearchChange}
            sx={{ mb: 2 }}
          />
        </Box>
        
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>User</TableCell>
                <TableCell>School</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Created</TableCell>
                <TableCell>Last Active</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredUsers
                .slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
                .map((user) => (
                  <TableRow key={user.id}>
                    <TableCell>
                      <Typography variant="body1">{user.displayName}</Typography>
                      <Typography variant="body2" color="text.secondary">
                        {user.email}
                      </Typography>
                    </TableCell>
                    <TableCell>{user.schoolName}</TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', gap: 1 }}>
                        {user.isPremium && (
                          <Chip
                            label="Premium"
                            color="primary"
                            size="small"
                          />
                        )}
                        {user.isBlocked ? (
                          <Chip
                            label="Blocked"
                            color="error"
                            size="small"
                          />
                        ) : (
                          <Chip
                            label="Active"
                            color="success"
                            size="small"
                          />
                        )}
                      </Box>
                    </TableCell>
                    <TableCell>
                      {user.createdAt.toLocaleDateString()}
                    </TableCell>
                    <TableCell>
                      {user.lastActive.toLocaleDateString()}
                    </TableCell>
                    <TableCell align="right">
                      <IconButton
                        color="primary"
                        onClick={() => handleOpenDialog(user, 'edit')}
                      >
                        <EditIcon />
                      </IconButton>
                      {user.isBlocked ? (
                        <IconButton
                          color="success"
                          onClick={() => handleOpenDialog(user, 'unblock')}
                        >
                          <CheckCircleIcon />
                        </IconButton>
                      ) : (
                        <IconButton
                          color="warning"
                          onClick={() => handleOpenDialog(user, 'block')}
                        >
                          <BlockIcon />
                        </IconButton>
                      )}
                      <IconButton
                        color="error"
                        onClick={() => handleOpenDialog(user, 'delete')}
                      >
                        <DeleteIcon />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
            </TableBody>
          </Table>
        </TableContainer>
        
        <TablePagination
          rowsPerPageOptions={[5, 10, 25]}
          component="div"
          count={filteredUsers.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
        />
      </Paper>
      
      {/* Dialog for user actions */}
      <Dialog
        open={openDialog}
        onClose={handleCloseDialog}
      >
        <DialogTitle>
          {dialogType === 'edit' && 'Edit User'}
          {dialogType === 'delete' && 'Delete User'}
          {dialogType === 'block' && 'Block User'}
          {dialogType === 'unblock' && 'Unblock User'}
        </DialogTitle>
        <DialogContent>
          <DialogContentText>
            {dialogType === 'edit' && `Edit user ${selectedUser?.displayName} (${selectedUser?.email})`}
            {dialogType === 'delete' && `Are you sure you want to delete ${selectedUser?.displayName} (${selectedUser?.email})? This action cannot be undone.`}
            {dialogType === 'block' && `Are you sure you want to block ${selectedUser?.displayName} (${selectedUser?.email})?`}
            {dialogType === 'unblock' && `Are you sure you want to unblock ${selectedUser?.displayName} (${selectedUser?.email})?`}
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          <Button onClick={handleUpdateUser} color="primary" autoFocus>
            {dialogType === 'edit' && 'Save'}
            {dialogType === 'delete' && 'Delete'}
            {dialogType === 'block' && 'Block'}
            {dialogType === 'unblock' && 'Unblock'}
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
};

export default UserManagement; 