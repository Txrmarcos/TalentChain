"use client";
import React, { useState, useEffect } from 'react';
import { User, Briefcase, Star, DollarSign, Clock, CheckCircle, AlertCircle, Plus, Filter, Search } from 'lucide-react';

// Mock Data
const mockUser = {
  id: '1',
  name: 'João Silva',
  email: 'joao@email.com',
  userType: 'client',
  skills: ['React', 'TypeScript', 'Node.js'],
  reputation: 4.8,
  totalProjects: 47,
  balance: 2500,
  avatar: 'JS'
};

const mockProjects = [
  {
    id: 1,
    title: 'DApp de NFT Marketplace',
    description: 'Preciso desenvolver um marketplace completo para NFTs no ICP com funcionalidades avançadas...',
    budget: 5000,
    status: 'open',
    clientId: '1',
    skills: ['Motoko', 'React', 'Web3'],
    deadline: '2025-09-15',
    proposals: 8
  },
  {
    id: 2,
    title: 'Sistema de Votação Descentralizado',
    description: 'Desenvolvimento de um sistema de votação transparente e seguro usando blockchain...',
    budget: 3500,
    status: 'in_progress',
    clientId: '1',
    skills: ['Blockchain', 'Smart Contracts'],
    deadline: '2025-08-30',
    proposals: 12,
    selectedFreelancer: 'Maria Santos'
  }
];

const mockFreelancers = [
  {
    id: 'f1',
    name: 'Maria Santos',
    skills: ['Motoko', 'React', 'Blockchain'],
    rating: 4.9,
    projects: 23,
    hourlyRate: 85,
    avatar: 'MS',
    badges: ['Top Rated', 'Blockchain Expert']
  },
  {
    id: 'f2',
    name: 'Pedro Lima',
    skills: ['TypeScript', 'Node.js', 'Smart Contracts'],
    rating: 4.7,
    projects: 31,
    hourlyRate: 75,
    avatar: 'PL',
    badges: ['Experienced Developer']
  }
];

const mockEscrowContracts = [
  {
    id: 1,
    projectId: 2,
    amount: 3500,
    status: 'funded',
    freelancer: 'Maria Santos',
    milestones: [
      { id: 1, description: 'Setup inicial', amount: 1000, status: 'completed' },
      { id: 2, description: 'Desenvolvimento core', amount: 1500, status: 'in_progress' },
      { id: 3, description: 'Testes e entrega', amount: 1000, status: 'pending' }
    ]
  }
];

const mockReviews = [
  {
    id: 1,
    projectId: 1,
    rating: 5,
    comment: 'Trabalho excepcional! Entregou antes do prazo e com qualidade superior.',
    reviewer: 'Ana Costa',
    freelancer: 'Maria Santos',
    date: '2025-07-15'
  }
];

// Components
const StatusBadge = ({ status }: any) => {
  const statusConfig:any = {
    open: { color: 'bg-green-100 text-green-800', text: 'Aberto' },
    in_progress: { color: 'bg-orange-100 text-orange-800', text: 'Em Andamento' },
    completed: { color: 'bg-blue-100 text-blue-800', text: 'Concluído' },
    funded: { color: 'bg-purple-100 text-purple-800', text: 'Financiado' },
    pending: { color: 'bg-gray-100 text-gray-800', text: 'Pendente' }
  };
  
  const config = statusConfig[status] || statusConfig.pending;
  
  return (
    <span className={`px-2 py-1 rounded-full text-xs font-medium ${config.color}`}>
      {config.text}
    </span>
  );
};

const StarRating = ({ rating, size = 'sm' }:any) => {
  const stars = [];
  const sizeClass = size === 'lg' ? 'w-6 h-6' : 'w-4 h-4';
  
  for (let i = 1; i <= 5; i++) {
    stars.push(
      <Star 
        key={i}
        className={`${sizeClass} ${i <= rating ? 'fill-yellow-400 text-yellow-400' : 'text-gray-300'}`}
      />
    );
  }
  
  return <div className="flex gap-1">{stars}</div>;
};

const Modal = ({ isOpen, onClose, title, children }:any) => {
  if (!isOpen) return null;
  
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b">
          <div className="flex justify-between items-center">
            <h2 className="text-xl font-semibold">{title}</h2>
            <button 
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 text-2xl"
            >
              ×
            </button>
          </div>
        </div>
        <div className="p-6">
          {children}
        </div>
      </div>
    </div>
  );
};

export default function TalentChainApp() {
  const [activeSection, setActiveSection] = useState('dashboard');
  const [showModal, setShowModal] = useState(false);
  const [modalType, setModalType] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  
  // Dashboard Section
  const Dashboard = () => (
    <div className="space-y-6">
      {/* Stats Overview */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm">
          <div className="flex items-center">
            <div className="p-3 bg-blue-100 rounded-lg">
              <Briefcase className="w-6 h-6 text-blue-600" />
            </div>
            <div className="ml-4">
              <p className="text-gray-500 text-sm">Projetos Ativos</p>
              <p className="text-2xl font-semibold">12</p>
            </div>
          </div>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-sm">
          <div className="flex items-center">
            <div className="p-3 bg-green-100 rounded-lg">
              <DollarSign className="w-6 h-6 text-green-600" />
            </div>
            <div className="ml-4">
              <p className="text-gray-500 text-sm">Saldo Total</p>
              <p className="text-2xl font-semibold">2.500 ICP</p>
            </div>
          </div>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-sm">
          <div className="flex items-center">
            <div className="p-3 bg-yellow-100 rounded-lg">
              <Star className="w-6 h-6 text-yellow-600" />
            </div>
            <div className="ml-4">
              <p className="text-gray-500 text-sm">Avaliação</p>
              <p className="text-2xl font-semibold">4.8</p>
            </div>
          </div>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-sm">
          <div className="flex items-center">
            <div className="p-3 bg-purple-100 rounded-lg">
              <CheckCircle className="w-6 h-6 text-purple-600" />
            </div>
            <div className="ml-4">
              <p className="text-gray-500 text-sm">Concluídos</p>
              <p className="text-2xl font-semibold">47</p>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="bg-white rounded-lg shadow-sm">
        <div className="p-6 border-b">
          <h3 className="text-lg font-semibold">Atividades Recentes</h3>
        </div>
        <div className="p-6">
          <div className="space-y-4">
            <div className="flex items-center space-x-3">
              <div className="w-2 h-2 bg-green-400 rounded-full"></div>
              <p className="text-sm">Maria Santos completou milestone "Setup inicial"</p>
              <span className="text-xs text-gray-500">2h atrás</span>
            </div>
            <div className="flex items-center space-x-3">
              <div className="w-2 h-2 bg-blue-400 rounded-full"></div>
              <p className="text-sm">Nova proposta recebida para "DApp de NFT Marketplace"</p>
              <span className="text-xs text-gray-500">4h atrás</span>
            </div>
            <div className="flex items-center space-x-3">
              <div className="w-2 h-2 bg-yellow-400 rounded-full"></div>
              <p className="text-sm">Pagamento de 1.000 ICP liberado no escrow #1</p>
              <span className="text-xs text-gray-500">1d atrás</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  // Projects Section
  const Projects = () => (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">Meus Projetos</h2>
        <button 
          onClick={() => {setModalType('create-project'); setShowModal(true);}}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-blue-700"
        >
          <Plus className="w-4 h-4" />
          Novo Projeto
        </button>
      </div>
      
      <div className="grid gap-6">
        {mockProjects.map(project => (
          <div key={project.id} className="bg-white rounded-lg shadow-sm p-6">
            <div className="flex justify-between items-start mb-4">
              <div>
                <h3 className="text-lg font-semibold mb-2">{project.title}</h3>
                <p className="text-gray-600 text-sm mb-3">{project.description}</p>
              </div>
              <StatusBadge status={project.status} />
            </div>
            
            <div className="flex flex-wrap gap-2 mb-4">
              {project.skills.map(skill => (
                <span key={skill} className="bg-blue-100 text-blue-800 px-2 py-1 rounded text-xs">
                  {skill}
                </span>
              ))}
            </div>
            
            <div className="flex justify-between items-center">
              <div className="flex items-center gap-4 text-sm text-gray-500">
                <span className="flex items-center gap-1">
                  <DollarSign className="w-4 h-4" />
                  {project.budget.toLocaleString()} ICP
                </span>
                <span className="flex items-center gap-1">
                  <Clock className="w-4 h-4" />
                  {project.deadline}
                </span>
                <span>{project.proposals} propostas</span>
              </div>
              <button className="text-blue-600 hover:text-blue-800 font-medium">
                Ver Detalhes
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  // Freelancers Section
  const Freelancers = () => (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">Freelancers Top</h2>
        <div className="flex gap-3">
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-3 text-gray-400" />
            <input 
              type="text" 
              placeholder="Buscar freelancers..."
              className="pl-10 pr-4 py-2 border rounded-lg"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <button className="border px-4 py-2 rounded-lg flex items-center gap-2">
            <Filter className="w-4 h-4" />
            Filtros
          </button>
        </div>
      </div>
      
      <div className="grid md:grid-cols-2 gap-6">
        {mockFreelancers.map(freelancer => (
          <div key={freelancer.id} className="bg-white rounded-lg shadow-sm p-6">
            <div className="flex items-start gap-4 mb-4">
              <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full flex items-center justify-center text-white font-semibold">
                {freelancer.avatar}
              </div>
              <div className="flex-1">
                <h3 className="font-semibold text-lg">{freelancer.name}</h3>
                <div className="flex items-center gap-2 mb-2">
                  <StarRating rating={freelancer.rating} />
                  <span className="text-sm text-gray-500">({freelancer.projects} projetos)</span>
                </div>
                <p className="text-green-600 font-medium">${freelancer.hourlyRate}/hora</p>
              </div>
            </div>
            
            <div className="mb-4">
              <div className="flex flex-wrap gap-2">
                {freelancer.skills.map(skill => (
                  <span key={skill} className="bg-gray-100 text-gray-700 px-2 py-1 rounded text-xs">
                    {skill}
                  </span>
                ))}
              </div>
            </div>
            
            <div className="flex flex-wrap gap-2 mb-4">
              {freelancer.badges.map(badge => (
                <span key={badge} className="bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs font-medium">
                  {badge}
                </span>
              ))}
            </div>
            
            <div className="flex gap-2">
              <button className="flex-1 bg-blue-600 text-white py-2 rounded hover:bg-blue-700">
                Contratar
              </button>
              <button className="px-4 py-2 border rounded hover:bg-gray-50">
                Ver Perfil
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  // Escrow Section  
  const Escrow = () => (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold">Contratos de Escrow</h2>
      
      {mockEscrowContracts.map(contract => (
        <div key={contract.id} className="bg-white rounded-lg shadow-sm p-6">
          <div className="flex justify-between items-start mb-6">
            <div>
              <h3 className="text-lg font-semibold mb-2">Contrato #{contract.id}</h3>
              <p className="text-gray-600">Freelancer: {contract.freelancer}</p>
              <p className="text-lg font-semibold text-green-600 mt-2">
                {contract.amount.toLocaleString()} ICP
              </p>
            </div>
            <StatusBadge status={contract.status} />
          </div>
          
          <div className="space-y-4">
            <h4 className="font-medium">Milestones do Projeto</h4>
            {contract.milestones.map(milestone => (
              <div key={milestone.id} className="flex items-center justify-between p-4 border rounded-lg">
                <div>
                  <h5 className="font-medium">{milestone.description}</h5>
                  <p className="text-green-600 font-medium">{milestone.amount.toLocaleString()} ICP</p>
                </div>
                <div className="flex items-center gap-3">
                  <StatusBadge status={milestone.status} />
                  {milestone.status === 'completed' && (
                    <button className="bg-green-600 text-white px-3 py-1 rounded text-sm hover:bg-green-700">
                      Aprovar
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );

  // Reputation Section
  const Reputation = () => (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold">Sistema de Reputação</h2>
      
      <div className="bg-white rounded-lg shadow-sm p-6">
        <h3 className="text-lg font-semibold mb-4">Minha Reputação</h3>
        <div className="grid md:grid-cols-3 gap-6">
          <div className="text-center">
            <div className="text-3xl font-bold text-blue-600 mb-2">4.8</div>
            <StarRating rating={4.8} size="lg" />
            <p className="text-gray-500 mt-2">Avaliação Média</p>
          </div>
          <div className="text-center">
            <div className="text-3xl font-bold text-green-600 mb-2">47</div>
            <p className="text-gray-500">Projetos Concluídos</p>
          </div>
          <div className="text-center">
            <div className="text-3xl font-bold text-purple-600 mb-2">3</div>
            <p className="text-gray-500">Badges Conquistadas</p>
          </div>
        </div>
      </div>
      
      <div className="bg-white rounded-lg shadow-sm p-6">
        <h3 className="text-lg font-semibold mb-4">Reviews Recentes</h3>
        <div className="space-y-4">
          {mockReviews.map(review => (
            <div key={review.id} className="border-b pb-4 last:border-b-0">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <StarRating rating={review.rating} />
                  <span className="font-medium">{review.reviewer}</span>
                </div>
                <span className="text-sm text-gray-500">{review.date}</span>
              </div>
              <p className="text-gray-700">{review.comment}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  // Create Project Modal
  const CreateProjectModal = () => (
    <div className="space-y-4">
      <div>
        <label className="block text-sm font-medium mb-2">Título do Projeto</label>
        <input type="text" className="w-full p-3 border rounded-lg" placeholder="Ex: Desenvolvimento de DApp..." />
      </div>
      
      <div>
        <label className="block text-sm font-medium mb-2">Descrição</label>
        <textarea className="w-full p-3 border rounded-lg h-32" placeholder="Descreva os detalhes do projeto..."></textarea>
      </div>
      
      <div className="grid md:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium mb-2">Orçamento (ICP)</label>
          <input type="number" className="w-full p-3 border rounded-lg" placeholder="0" />
        </div>
        <div>
          <label className="block text-sm font-medium mb-2">Prazo (dias)</label>
          <input type="number" className="w-full p-3 border rounded-lg" placeholder="30" />
        </div>
      </div>
      
      <div>
        <label className="block text-sm font-medium mb-2">Skills Necessárias</label>
        <input type="text" className="w-full p-3 border rounded-lg" placeholder="React, TypeScript, Motoko..." />
      </div>
      
      <div className="flex gap-3 pt-4">
        <button className="flex-1 bg-blue-600 text-white py-3 rounded-lg hover:bg-blue-700">
          Criar Projeto
        </button>
        <button 
          onClick={() => setShowModal(false)}
          className="px-6 py-3 border rounded-lg hover:bg-gray-50"
        >
          Cancelar
        </button>
      </div>
    </div>
  );

  const renderSection = () => {
    switch(activeSection) {
      case 'dashboard': return <Dashboard />;
      case 'projects': return <Projects />;
      case 'freelancers': return <Freelancers />;
      case 'escrow': return <Escrow />;
      case 'reputation': return <Reputation />;
      default: return <Dashboard />;
    }
  };

  const renderModal = () => {
    switch(modalType) {
      case 'create-project': return <CreateProjectModal />;
      default: return null;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center gap-8">
              <h1 className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
                🔗 TalentChain
              </h1>
              <nav className="flex space-x-6">
                {[
                  { id: 'dashboard', label: 'Dashboard', icon: User },
                  { id: 'projects', label: 'Projetos', icon: Briefcase },
                  { id: 'freelancers', label: 'Freelancers', icon: User },
                  { id: 'escrow', label: 'Escrow', icon: DollarSign },
                  { id: 'reputation', label: 'Reputação', icon: Star }
                ].map(item => (
                  <button
                    key={item.id}
                    onClick={() => setActiveSection(item.id)}
                    className={`flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                      activeSection === item.id 
                        ? 'bg-blue-100 text-blue-700' 
                        : 'text-gray-600 hover:text-gray-900'
                    }`}
                  >
                    <item.icon className="w-4 h-4" />
                    {item.label}
                  </button>
                ))}
              </nav>
            </div>
            
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-3 bg-gradient-to-r from-blue-50 to-purple-50 px-4 py-2 rounded-lg">
                <DollarSign className="w-4 h-4 text-blue-600" />
                <span className="font-semibold text-blue-700">2.500 ICP</span>
              </div>
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full flex items-center justify-center text-white font-semibold text-sm">
                  {mockUser.avatar}
                </div>
                <span className="font-medium">{mockUser.name}</span>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {renderSection()}
      </main>

      {/* Modal */}
      <Modal 
        isOpen={showModal} 
        onClose={() => setShowModal(false)}
        title={modalType === 'create-project' ? 'Criar Novo Projeto' : ''}
      >
        {renderModal()}
      </Modal>
    </div>
  );
}