import { actor } from './actor.js';

function formatCycles(cycles) {
    if (cycles >= 1_000_000_000_000) {
        return (cycles / 1_000_000_000_000).toFixed(2) + ' T';
    } else if (cycles >= 1_000_000_000) {
        return (cycles / 1_000_000_000).toFixed(2) + ' B';
    } else if (cycles >= 1_000_000) {
        return (cycles / 1_000_000).toFixed(2) + ' M';
    } else if (cycles >= 1_000) {
        return (cycles / 1_000).toFixed(2) + ' K';
    }
    return cycles.toString();
}

const MAX_CYCLES = 5_000_000_000_000;

async function updateBalance() {
    try {
        // const response = await fetch('/balance', {
        //     method: 'GET',
        //     headers: {
        //         'Content-Type': 'application/json',
        //     },
        // });
        
        // const balance = parseInt(await response.text());

        const balance = Number(await actor.get_cycle_balance());
        
        // Calculate percentage (capped at 100%)
        const percentage = Math.min((balance / MAX_CYCLES) * 100, 100);
        
        // Update energy bar
        const energyFill = document.getElementById('energy-fill');
        energyFill.style.width = `${percentage}%`;
        
        // Update text displays
        document.getElementById('energy-text').innerText = 
            `${formatCycles(balance)} cycles`;
        document.getElementById('raw-balance').innerText = 
            `Total: ${formatCycles(balance)} cycles`;
        document.getElementById('percentage').innerText = 
            `${percentage.toFixed(1)}% of max capacity`;

        // Change color based on percentage
        if (percentage < 20) {
            energyFill.style.background = 'linear-gradient(90deg, #ff5252, #ff8a80)';
        } else if (percentage < 50) {
            energyFill.style.background = 'linear-gradient(90deg, #ffd740, #ffecb3)';
        } else {
            energyFill.style.background = 'linear-gradient(90deg, #4CAF50, #8BC34A)';
        }

    } catch (error) {
        console.error('Error fetching balance:', error);
    }
}

export { updateBalance };